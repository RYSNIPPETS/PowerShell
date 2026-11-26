<#
.SYNOPSIS
    Disables automatic Windows Update checks through policy.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch]$StopServices,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsWindows) { throw 'This script requires Windows.' }
$subkey = 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
$policyPath = "HKLM:\$subkey"

[Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($subkey).Dispose()
New-ItemProperty -Path $policyPath -Name NoAutoUpdate -PropertyType DWord -Value 1 -Force | Out-Null

if ($StopServices) {
    foreach ($serviceName in 'wuauserv', 'BITS') {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -ne 'Stopped') {
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
        }
    }
}

Write-Warning 'Automatic updates are disabled by local policy. Re-enable them promptly to continue receiving security fixes.'
