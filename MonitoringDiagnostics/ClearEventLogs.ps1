<#
.SYNOPSIS
    Archives and clears selected Windows event logs locally or remotely.
.DESCRIPTION
    Enabled logs are selected by default. Use -AllLogs to include disabled logs. When -ArchivePath is
    supplied, remote logs are exported to a temporary file and copied back through the PowerShell session.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('Name')]
    [string[]]$ComputerName = @($env:COMPUTERNAME),

    [string[]]$Include = @('Application', 'System', 'Security'),

    [string[]]$Exclude,

    [ValidateRange(0, [long]::MaxValue)]
    [long]$MinRecordCount = 0,

    [switch]$AllLogs,

    [string]$ArchivePath,

    [switch]$SkipArchive,

    [pscredential]$Credential,

    [switch]$UseSSL,

    [Parameter(DontShow)]
    [switch]$Confirm
)

begin {
    $ConfirmPreference = 'None'
    if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

    $summary = [Collections.Generic.List[object]]::new()
    $getLogBlock = {
        param($IncludePattern, $ExcludePattern, $MinimumRecords, $IncludeDisabled)

        Get-WinEvent -ListLog '*' -ErrorAction SilentlyContinue |
            Where-Object {
                $log = $_
                $included = $IncludePattern.Count -eq 0 -or @($IncludePattern | Where-Object { $log.LogName -like $_ }).Count -gt 0
                $excluded = @($ExcludePattern | Where-Object { $log.LogName -like $_ }).Count -gt 0
                $included -and -not $excluded -and ($IncludeDisabled -or $log.IsEnabled) -and $log.RecordCount -ge $MinimumRecords
            } |
            Select-Object LogName, RecordCount, IsEnabled
    }
    $clearBlock = {
        param($EventLogName, $BackupPath)

        $arguments = @('cl', $EventLogName)
        if ($BackupPath) { $arguments += "/bu:$BackupPath" }
        & "$env:SystemRoot\System32\wevtutil.exe" @arguments
        if ($LASTEXITCODE -ne 0) { throw "Could not clear '$EventLogName' (wevtutil exit $LASTEXITCODE)." }
    }
}

process {
    foreach ($computer in $ComputerName) {
        $isLocal = $computer -in '.', 'localhost', $env:COMPUTERNAME
        $session = $null
        try {
            if ($isLocal) {
                $logs = & $getLogBlock $Include $Exclude $MinRecordCount $AllLogs.IsPresent
            }
            else {
                $sessionParameters = @{ ComputerName = $computer; UseSSL = $UseSSL }
                if ($Credential) { $sessionParameters.Credential = $Credential }
                $session = New-PSSession @sessionParameters -ErrorAction Stop
                $logs = Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock $getLogBlock -ArgumentList $Include, $Exclude, $MinRecordCount, $AllLogs.IsPresent
            }

            foreach ($log in $logs) {
                $archive = -not $SkipArchive -and $ArchivePath

                $safeLogName = $log.LogName -replace '[\\/:*?"<>|]', '_'
                $fileName = '{0}_{1}_{2}.evtx' -f $computer.Trim('.'), $safeLogName, [guid]::NewGuid().ToString('N')
                $backupPath = $null
                $localFile = $null
                $cleared = $false
                $archived = $false
                $failure = $null
                try {
                    if ($archive) {
                        $folder = New-Item -ItemType Directory -Path $ArchivePath -Force -ErrorAction Stop
                        $localFile = Join-Path $folder.FullName $fileName
                        $backupPath = if ($isLocal) { $localFile } else {
                            Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock { Join-Path ([IO.Path]::GetTempPath()) $using:fileName }
                        }
                    }
                    if ($isLocal) { & $clearBlock $log.LogName $backupPath }
                    else { Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock $clearBlock -ArgumentList $log.LogName, $backupPath }
                    $cleared = $true
                    if ($archive -and -not $isLocal) {
                        $expected = Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock {
                            (Get-FileHash -LiteralPath $using:backupPath -Algorithm SHA256 -ErrorAction Stop).Hash
                        }
                        Copy-Item -FromSession $session -LiteralPath $backupPath -Destination $localFile -ErrorAction Stop
                        if ((Get-FileHash -LiteralPath $localFile -Algorithm SHA256 -ErrorAction Stop).Hash -ne $expected) {
                            throw "Archive verification failed for '$localFile'."
                        }
                        $archived = $true
                        Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock { Remove-Item -LiteralPath $using:backupPath -Force -ErrorAction Stop }
                        $backupPath = $null
                    }
                    elseif ($archive) { $archived = $true }
                }
                catch { $failure = $_.Exception.Message }
                $summary.Add([pscustomobject]@{
                        ComputerName     = $computer
                        LogName          = $log.LogName
                        Cleared          = $cleared
                        Archived         = $archived
                        ArchivePath      = if ($archived) { $localFile }
                        RemoteBackupPath = if (-not $isLocal) { $backupPath }
                        Error            = $failure
                    })
            }
        }
        catch {
            $summary.Add([pscustomobject]@{
                    ComputerName     = $computer
                    LogName          = $null
                    Cleared          = $false
                    Archived         = $false
                    ArchivePath      = $null
                    RemoteBackupPath = $null
                    Error            = $_.Exception.Message
                })
        }
        finally {
            if ($session) { Remove-PSSession -Session $session }
        }
    }
}

end {
    $summary
}
