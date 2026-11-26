<#
.SYNOPSIS
    Installs the Windows OpenSSH client capability.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$capability = Get-WindowsCapability -Online -Name 'OpenSSH.Client*' -ErrorAction Stop |
    Select-Object -First 1
if (-not $capability) {
    throw 'The OpenSSH.Client Windows capability is not available on this operating system.'
}

if ($capability.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $capability.Name
}
else {
    $capability
}
