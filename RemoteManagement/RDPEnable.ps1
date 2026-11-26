<#
.SYNOPSIS
    Enables Remote Desktop connections and its firewall rules.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Set-ItemProperty -LiteralPath 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0 -Type DWord
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
