<#
.SYNOPSIS
    Runs a selected Repadmin diagnostic or synchronization operation.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [ValidateSet('Kcc', 'Queue', 'ReplSummary', 'ShowBackup', 'ShowRepl', 'ShowUtdVec', 'SyncAll')]
    [string]$Operation = 'ReplSummary',

    [string]$DomainController = '*',

    [pscredential]$Credential,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$arguments = switch ($Operation) {
    'Kcc' { @('/kcc', $DomainController) }
    'Queue' { @('/queue', $DomainController) }
    'ReplSummary' { @('/replsummary', $DomainController) }
    'ShowBackup' { @('/showbackup', $DomainController) }
    'ShowRepl' { @('/showrepl', $DomainController) }
    'ShowUtdVec' { @('/showutdvec', $DomainController, '*', '/latency') }
    'SyncAll' { @('/syncall', $DomainController, '/A', '/e', '/P') }
}

if ($Credential) {
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = Join-Path $env:SystemRoot 'System32\repadmin.exe'
    $account = $Credential.GetNetworkCredential()
    $startInfo.UserName = $account.UserName
    if ($account.Domain) { $startInfo.Domain = $account.Domain }
    $startInfo.Password = $Credential.Password
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    foreach ($argument in $arguments) { $startInfo.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::Start($startInfo)
    try {
        while ($null -ne ($line = $process.StandardOutput.ReadLine())) { $line }
        $process.WaitForExit()
        $exitCode = $process.ExitCode
    }
    finally { $process.Dispose() }
}
else {
    & "$env:SystemRoot\System32\repadmin.exe" @arguments
    $exitCode = $LASTEXITCODE
}
if ($exitCode -ne 0) { throw "repadmin.exe failed with exit code $exitCode." }
