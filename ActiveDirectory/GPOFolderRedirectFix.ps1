<#
.SYNOPSIS
    Backs up and optionally clears local Group Policy registry caches before refreshing policy.
.DESCRIPTION
    Clearing these policy keys is disruptive. Backups are exported before removal and -ResetPolicyCache
    must be specified explicitly. The script no longer changes DNS server addresses.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$BackupDirectory = (Join-Path $env:SystemDrive 'PolicyRegistryBackup'),

    [switch]$ResetPolicyCache,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$entries = @(
    @{ NativePath = 'HKLM\Software\Policies\Microsoft'; ProviderPath = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft'; FileName = 'HKLM_Policies_Microsoft.reg' },
    @{ NativePath = 'HKCU\Software\Policies\Microsoft'; ProviderPath = 'Registry::HKEY_CURRENT_USER\Software\Policies\Microsoft'; FileName = 'HKCU_Policies_Microsoft.reg' },
    @{ NativePath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects'; ProviderPath = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects'; FileName = 'HKCU_GroupPolicyObjects.reg' },
    @{ NativePath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies'; ProviderPath = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies'; FileName = 'HKCU_CurrentVersion_Policies.reg' }
)

$runDirectory = Join-Path $BackupDirectory ([guid]::NewGuid().ToString('N'))

$null = New-Item -ItemType Directory -Path $runDirectory -Force -ErrorAction Stop

foreach ($entry in $entries) {
    if (-not (Test-Path -LiteralPath $entry.ProviderPath)) { continue }
    $backupPath = Join-Path $runDirectory $entry.FileName

    & "$env:SystemRoot\System32\reg.exe" export $entry.NativePath $backupPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to export '$($entry.NativePath)'." }

    if ($ResetPolicyCache) {
        Remove-Item -LiteralPath $entry.ProviderPath -Recurse -Force -Confirm:$false -ErrorAction Stop
    }
}

& "$env:SystemRoot\System32\gpupdate.exe" /force
if ($LASTEXITCODE -ne 0) { throw "gpupdate.exe failed with exit code $LASTEXITCODE." }
