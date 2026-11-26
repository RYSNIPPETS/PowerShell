<#
.SYNOPSIS
    Installs AD DS and promotes the local Windows Server to a domain controller.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$DomainName,

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

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop

Import-Module ADDSDeployment -ErrorAction Stop

$parameters = @{
    DomainName                    = $DomainName
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
