<#
.SYNOPSIS
    Promotes the local Windows Server to a domain controller using installation media.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$DomainName,

    [Parameter(Mandatory)]
    [string]$InstallationMediaPath,

    [Parameter(Mandatory)]
    [securestring]$SafeModeAdministratorPassword,

    [pscredential]$Credential,

    [string]$SiteName,

    [string]$DatabasePath = 'C:\Windows\NTDS',

    [string]$LogPath = 'C:\Windows\NTDS',

    [string]$SysvolPath = 'C:\Windows\SYSVOL',

    [switch]$NoRebootOnCompletion,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not (Test-Path -LiteralPath $InstallationMediaPath -PathType Container)) {
    throw "Installation media path '$InstallationMediaPath' was not found."
}

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop

Import-Module ADDSDeployment -ErrorAction Stop

$parameters = @{
    DomainName                    = $DomainName
    InstallationMediaPath         = $InstallationMediaPath
    SafeModeAdministratorPassword = $SafeModeAdministratorPassword
    InstallDns                    = $true
    NoGlobalCatalog               = $false
    DatabasePath                  = $DatabasePath
    LogPath                       = $LogPath
    SysvolPath                    = $SysvolPath
    NoRebootOnCompletion          = $NoRebootOnCompletion
    Force                         = $true
}
if ($Credential) { $parameters.Credential = $Credential }
if ($SiteName) { $parameters.SiteName = $SiteName }

Install-ADDSDomainController @parameters
