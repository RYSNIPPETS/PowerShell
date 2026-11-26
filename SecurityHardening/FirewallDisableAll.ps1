<#
.SYNOPSIS
    Disables selected Windows Defender Firewall profiles.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [ValidateSet('Domain', 'Private', 'Public')]
    [string[]]$FirewallProfile = @('Domain', 'Private', 'Public'),

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Set-NetFirewallProfile -Profile $FirewallProfile -Enabled False
