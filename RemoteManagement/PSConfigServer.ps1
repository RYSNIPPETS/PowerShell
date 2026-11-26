#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Manages powershell config server.
#>

[CmdletBinding()]
param(
    [switch]$EnableCredSSP,

    [ValidateSet('DoNotChange', 'RemoteSigned', 'AllSigned', 'Bypass')]
    [string]$ExecutionPolicy = 'DoNotChange',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsWindows) { throw 'This script requires Windows.' }

Enable-PSRemoting -Force -SkipNetworkProfileCheck

if ($EnableCredSSP) {
    Enable-WSManCredSSP -Role Server -Force
}

if ($ExecutionPolicy -ne 'DoNotChange') {
    Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy $ExecutionPolicy -Force
}
