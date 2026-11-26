<#
.SYNOPSIS
    Enables a local account and optionally assigns a new password.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$Name = 'Administrator',

    [securestring]$Password,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$user = Get-LocalUser -Name $Name -ErrorAction Stop

$user | Enable-LocalUser
if ($Password) {
    Set-LocalUser -Name $Name -Password $Password
}
Get-LocalUser -Name $Name
