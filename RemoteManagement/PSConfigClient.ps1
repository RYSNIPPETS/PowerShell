#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Manages powershell config client.
#>

[CmdletBinding()]
param(
    [string[]]$TrustedHosts,

    [switch]$EnableCredSSP,

    [string[]]$DelegateComputer,

    [ValidateSet('DoNotChange', 'RemoteSigned', 'AllSigned', 'Bypass')]
    [string]$ExecutionPolicy = 'DoNotChange',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsWindows) { throw 'This script requires Windows.' }

Enable-PSRemoting -Force -SkipNetworkProfileCheck

if ($TrustedHosts) {
    $trustedHostsValue = $TrustedHosts -join ','

    Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $trustedHostsValue -Force
    Restart-Service -Name WinRM
}

if ($EnableCredSSP) {
    if (-not $DelegateComputer) {
        throw 'Provide -DelegateComputer when using -EnableCredSSP.'
    }

    Enable-WSManCredSSP -Role Client -DelegateComputer $DelegateComputer -Force
}

if ($ExecutionPolicy -ne 'DoNotChange') {
    Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy $ExecutionPolicy -Force
}
