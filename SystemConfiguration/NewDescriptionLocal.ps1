<#
.SYNOPSIS
    Sets the local Windows computer description.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Description,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Get-CimInstance -ClassName Win32_OperatingSystem |
    Set-CimInstance -Property @{ Description = $Description }
