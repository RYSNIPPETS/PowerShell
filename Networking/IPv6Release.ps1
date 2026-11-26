<#
.SYNOPSIS
    Releases IPv6 DHCP leases on Windows adapters.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string[]]$InterfaceAlias,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsWindows) { throw 'This script requires Windows.' }
$targets = if ($InterfaceAlias) { $InterfaceAlias } else { @('*') }
foreach ($target in $targets) {
    $arguments = if ($target -eq '*') { @('/release6') } else { @('/release6', $target) }
    & "$env:SystemRoot\System32\ipconfig.exe" @arguments
    if ($LASTEXITCODE -ne 0) { throw "ipconfig failed with exit code $LASTEXITCODE for '$target'." }
}
