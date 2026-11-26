<#
.SYNOPSIS
    Removes selected Windows Server roles or features and optionally their payloads.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$Name,

    [string]$ComputerName,

    [switch]$RemovePayload,

    [switch]$Restart,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{
    Name    = $Name
    Remove  = $RemovePayload
    Restart = $Restart
}
if ($ComputerName) {
    $parameters.ComputerName = $ComputerName
}

Uninstall-WindowsFeature @parameters
