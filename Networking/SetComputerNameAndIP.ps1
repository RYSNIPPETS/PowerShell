<#
.SYNOPSIS
    Configures a static IPv4 address, DNS servers, and computer name.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InterfaceAlias,

    [Parameter(Mandatory)]
    [ipaddress]$IPAddress,

    [ValidateRange(1, 32)]
    [int]$PrefixLength = 24,

    [Parameter(Mandatory)]
    [ipaddress]$DefaultGateway,

    [Parameter(Mandatory)]
    [ipaddress[]]$DnsServerAddress,

    [Parameter(Mandatory)]
    [string]$NewComputerName,

    [switch]$Restart,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway -AddressFamily IPv4
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DnsServerAddress

Rename-Computer -NewName $NewComputerName -Force -Restart:$Restart
