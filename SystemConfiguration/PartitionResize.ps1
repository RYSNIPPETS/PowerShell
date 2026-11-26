<#
.SYNOPSIS
    Expands a Windows partition to its maximum supported size.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z]$')]
    [string]$DriveLetter = 'C',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$size = Get-PartitionSupportedSize -DriveLetter $DriveLetter

Resize-Partition -DriveLetter $DriveLetter -Size $size.SizeMax
