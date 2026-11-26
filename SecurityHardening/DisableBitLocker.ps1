<#
.SYNOPSIS
    Starts BitLocker decryption for a volume.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z]:$')]
    [string]$MountPoint = 'C:',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Disable-BitLocker -MountPoint $MountPoint
