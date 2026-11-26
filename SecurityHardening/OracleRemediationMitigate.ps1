<#
.SYNOPSIS
    Configures the CredSSP encryption-oracle remediation policy.
.DESCRIPTION
    The vulnerable value (2) should only be used as a short-lived compatibility mitigation.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [ValidateSet(0, 1, 2)]
    [int]$ProtectionLevel = 0,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$subkey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters'
$path = "HKLM:\$subkey"

[Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($subkey).Dispose()
Set-ItemProperty -LiteralPath $path -Name AllowEncryptionOracle -Value $ProtectionLevel -Type DWord
if ($ProtectionLevel -eq 2) {
    Write-Warning 'ProtectionLevel 2 permits vulnerable CredSSP connections. Revert to 0 after affected hosts are patched.'
}
