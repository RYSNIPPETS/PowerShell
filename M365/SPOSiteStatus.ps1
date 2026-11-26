#Requires -Modules Microsoft.Online.SharePoint.PowerShell

<#
.SYNOPSIS
    Lists or changes SharePoint Online site lock states.
#>

[CmdletBinding(DefaultParameterSetName = 'Browser')]
param(
    [Parameter(Mandatory)]
    [string]$TenantName,

    [ValidateSet('ListNoAccess', 'ListReadOnly', 'SetNoAccess', 'SetReadOnly', 'Unlock')]
    [string]$Action = 'ListNoAccess',

    [string]$SiteUrl,

    [Parameter(Mandatory, ParameterSetName = 'Credential')]
    [pscredential]$Credential,

    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [string]$ClientId,

    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [string]$TenantId,

    [Parameter(ParameterSetName = 'Certificate')]
    [string]$CertificateThumbprint,

    [Parameter(ParameterSetName = 'Certificate')]
    [string]$CertificatePath,

    [Parameter(ParameterSetName = 'Certificate')]
    [securestring]$CertificatePassword,

    [string]$AuthenticationUrl = 'https://login.microsoftonline.com/organizations',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$adminUrl = 'https://{0}-admin.sharepoint.com' -f $TenantName
$connectParameters = @{ Url = $adminUrl }
switch ($PSCmdlet.ParameterSetName) {
    'Credential' {
        $connectParameters.Credential = $Credential
        $connectParameters.ModernAuth = $true
        $connectParameters.AuthenticationUrl = $AuthenticationUrl
    }
    'Certificate' {
        $connectParameters.ClientId = $ClientId
        $connectParameters.TenantId = $TenantId
        if ($CertificateThumbprint) {
            $connectParameters.CertificateThumbprint = $CertificateThumbprint
        }
        elseif ($CertificatePath) {
            $connectParameters.CertificatePath = $CertificatePath
            if ($CertificatePassword) { $connectParameters.CertificatePassword = $CertificatePassword }
        }
        else {
            throw 'Provide -CertificateThumbprint or -CertificatePath for certificate authentication.'
        }
    }
    default {
        throw 'Supply a credential or application certificate for unattended authentication.'
    }
}
Connect-SPOService @connectParameters

if ($Action -like 'List*') {
    $lockState = if ($Action -eq 'ListNoAccess') { 'NoAccess' } else { 'ReadOnly' }
    Get-SPOSite -Limit All |
        Where-Object LockState -EQ $lockState |
        Select-Object Url, Title, Owner, LockState
    return
}

if (-not $SiteUrl) { throw '-SiteUrl is required for state-changing actions.' }
$lockState = switch ($Action) {
    'SetNoAccess' { 'NoAccess' }
    'SetReadOnly' { 'ReadOnly' }
    'Unlock' { 'Unlock' }
}

Set-SPOSite -Identity $SiteUrl -LockState $lockState
Get-SPOSite -Identity $SiteUrl | Select-Object Url, Title, Owner, LockState
