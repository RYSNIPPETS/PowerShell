<#
.SYNOPSIS
    Applies a Windows product key to an offline Windows image.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9]{5}(?:-[A-Za-z0-9]{5}){4}$')]
    [string]$ProductKey,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Set-WindowsProductKey -Path $Path -ProductKey $ProductKey
