<#
.SYNOPSIS
    Disables User Account Control on Windows.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'

Set-ItemProperty -LiteralPath $path -Name EnableLUA -Value 0 -Type DWord
Write-Warning 'UAC is disabled after the next restart. This materially reduces Windows security.'
