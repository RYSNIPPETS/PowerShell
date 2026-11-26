<#
.SYNOPSIS
    Installs and enables the Windows OpenSSH server.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$capability = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' -ErrorAction Stop |
    Select-Object -First 1
if (-not $capability) {
    throw 'The OpenSSH.Server Windows capability is not available on this operating system.'
}

if ($capability.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $capability.Name
}

Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd

Get-Service -Name sshd
Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
