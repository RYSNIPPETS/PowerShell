<#
.SYNOPSIS
    Adds a network adapter to a Hyper-V virtual machine.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$VMName,

    [Parameter(Mandatory)]
    [string]$SwitchName,

    [Parameter(Mandatory)]
    [string]$Name,

    [string]$ComputerName,

    [switch]$Legacy,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{
    VMName     = $VMName
    SwitchName = $SwitchName
    Name       = $Name
    IsLegacy   = $Legacy
}
if ($ComputerName) { $parameters.ComputerName = $ComputerName }

Add-VMNetworkAdapter @parameters
