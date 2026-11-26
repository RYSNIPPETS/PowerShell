<#
.SYNOPSIS
    Restarts remote Windows computers listed in a text file using WSMan from a Windows controller.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ComputerListPath,

    [Parameter(Mandatory)]
    [pscredential]$Credential,

    [switch]$UseSsl,

    [switch]$Wait,

    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 300,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsWindows) { throw 'This script requires a Windows controller with WSMan remoting.' }

$computers = Get-Content -LiteralPath $ComputerListPath |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ } |
    Sort-Object -Unique

foreach ($computer in $computers) {
    $restartRequested = $false
    try {
        $connection = @{ ComputerName = $computer; Credential = $Credential; UseSSL = [bool]$UseSsl; ErrorAction = 'Stop' }
        $getBootTime = { (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime.ToUniversalTime().Ticks }
        if ($Wait) { $previousBoot = Invoke-Command @connection -ScriptBlock $getBootTime }
        Invoke-Command @connection -ScriptBlock {
            & "$env:SystemRoot\System32\shutdown.exe" /r /f /t 5
            if ($LASTEXITCODE -ne 0) { throw "Shutdown request failed with exit code $LASTEXITCODE." }
        }
        $restartRequested = $true
        if ($Wait) {
            $timer = [Diagnostics.Stopwatch]::StartNew()
            $ready = $false
            while ($timer.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
                $remainingMs = [int]($TimeoutSeconds * 1000 - $timer.Elapsed.TotalMilliseconds)
                if ($remainingMs -le 0) { break }
                Start-Sleep -Milliseconds ([Math]::Min(2000, $remainingMs))
                $remainingMs = [int]($TimeoutSeconds * 1000 - $timer.Elapsed.TotalMilliseconds)
                if ($remainingMs -le 0) { break }
                $job = $null
                try {
                    $job = Invoke-Command @connection -AsJob -ScriptBlock $getBootTime
                    $remainingSeconds = [int][math]::Ceiling($TimeoutSeconds - $timer.Elapsed.TotalSeconds)
                    if ($remainingSeconds -le 0) { break }
                    if (Wait-Job -Job $job -Timeout ([math]::Min(5, $remainingSeconds))) {
                        $currentBoot = Receive-Job -Job $job -ErrorAction Stop
                        if ($currentBoot -gt $previousBoot) { $ready = $true; break }
                    }
                }
                catch { Write-Verbose "Waiting for $computer to restart." }
                finally { if ($job) { Remove-Job -Job $job -Force } }
            }
            if (-not $ready) { throw "Restart requested, but PowerShell readiness was not confirmed within $TimeoutSeconds seconds." }
        }
        [pscustomobject]@{ ComputerName = $computer; RestartRequested = $true; Error = $null }
    }
    catch {
        [pscustomobject]@{ ComputerName = $computer; RestartRequested = $restartRequested; Error = $_.Exception.Message }
    }
}
