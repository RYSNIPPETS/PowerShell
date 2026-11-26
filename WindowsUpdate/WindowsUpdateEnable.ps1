<#
.SYNOPSIS
    Re-enables automatic Windows Update checks and restores core services to demand start.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch]$StartScan,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsWindows) { throw 'This script requires Windows.' }
$policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'

if ((Test-Path -LiteralPath $policyPath)) {
    Remove-ItemProperty -Path $policyPath -Name NoAutoUpdate -ErrorAction SilentlyContinue
}

foreach ($serviceName in 'wuauserv', 'BITS') {
    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        Set-Service -Name $serviceName -StartupType Manual -ErrorAction Stop
    }
}

if ($StartScan) {
    if (-not (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue)) {
        throw 'Install/import the PSWindowsUpdate module before using -StartScan.'
    }
    Get-WindowsUpdate
}
