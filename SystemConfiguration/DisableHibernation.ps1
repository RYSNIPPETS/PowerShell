<#
.SYNOPSIS
    Disables hibernation on Windows.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

& "$env:SystemRoot\System32\powercfg.exe" /hibernate off
if ($LASTEXITCODE -ne 0) {
    throw "powercfg.exe failed with exit code $LASTEXITCODE."
}
