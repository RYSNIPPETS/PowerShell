<#
.SYNOPSIS
    Installs selected RSAT Windows capabilities on Windows 10 or Windows 11.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string[]]$Name = @('Rsat.*'),

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsWindows) { throw 'This script requires Windows.' }

$capabilities = Get-WindowsCapability -Online |
    Where-Object {
        $capabilityName = $_.Name
        $_.State -eq 'NotPresent' -and
        @($Name | Where-Object { $capabilityName -like $_ }).Count -gt 0
    }

foreach ($capability in $capabilities) {
    Add-WindowsCapability -Online -Name $capability.Name
}
