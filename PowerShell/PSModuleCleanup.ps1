<#
.SYNOPSIS
    Removes superseded versions of modules installed through PSResourceGet.
#>

#Requires -Version 7.4

[CmdletBinding()]
param(
    [string[]]$Name = @('*'),

    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not (Get-Command Get-InstalledPSResource -ErrorAction SilentlyContinue)) {
    throw 'Microsoft.PowerShell.PSResourceGet is required.'
}

$installed = @(Get-InstalledPSResource -Name $Name -Scope $Scope)
foreach ($group in $installed | Group-Object Name) {
    $versions = @($group.Group | Sort-Object Version -Descending)
    if ($versions.Count -le 1) { continue }

    foreach ($oldResource in $versions | Select-Object -Skip 1) {
        Uninstall-PSResource -Name $oldResource.Name -Version $oldResource.Version -Scope $Scope -ErrorAction Stop
    }
}
