<#
.SYNOPSIS
    Installs or upgrades to the latest stable PowerShell release on Windows using WinGet.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    throw 'WinGet is required. Install or update App Installer, then run this script again.'
}

& $winget.Source upgrade --id Microsoft.PowerShell --exact --source winget --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
if ($LASTEXITCODE -ne 0) {
    # WinGet returns a non-success result when no installed package exists, so try install.
    & $winget.Source install --id Microsoft.PowerShell --exact --source winget --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
}
if ($LASTEXITCODE -ne 0) {
    throw "WinGet failed with exit code $LASTEXITCODE."
}
