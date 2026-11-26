<#
.SYNOPSIS
    Restarts Windows into the advanced startup options menu.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [ValidateRange(0, 3600)]
    [int]$DelaySeconds = 0,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

& "$env:SystemRoot\System32\shutdown.exe" /r /o /t $DelaySeconds
if ($LASTEXITCODE -ne 0) { throw "shutdown.exe failed with exit code $LASTEXITCODE." }
