<#
.SYNOPSIS
    Connects to Microsoft Purview compliance PowerShell and/or Exchange Online.
#>

#Requires -Modules ExchangeOnlineManagement

[CmdletBinding()]
param(    [string]$AppId,
    [string]$CertificateThumbprint,
    [string]$Organization,

    [switch]$Compliance,

    [switch]$ExchangeOnline,

    [switch]$SearchOnly,

    [switch]$UseDeviceAuthentication,

    [string]$UserPrincipalName
)

if ($UseDeviceAuthentication -or $UserPrincipalName -or -not ($AppId -and $CertificateThumbprint -and $Organization)) {
    throw 'Supply -Organization, -AppId and -CertificateThumbprint for unattended authentication.'
}

if (-not ($Compliance -or $ExchangeOnline)) {
    throw 'Specify -Compliance, -ExchangeOnline, or both.'
}
if ($SearchOnly -and -not $Compliance) {
    throw '-SearchOnly requires -Compliance.'
}

if ($Compliance) {
    $parameters = @{ AppId = $AppId; CertificateThumbprint = $CertificateThumbprint; Organization = $Organization; EnableSearchOnlySession = $SearchOnly }
    Connect-IPPSSession @parameters | Out-Null
}
if ($ExchangeOnline) {
    $parameters = @{ AppId = $AppId; CertificateThumbprint = $CertificateThumbprint; Organization = $Organization; ShowBanner = $false }
    Connect-ExchangeOnline @parameters | Out-Null
}

[pscustomobject]@{
    ComplianceConnected     = $Compliance.IsPresent
    ExchangeOnlineConnected = $ExchangeOnline.IsPresent
    SearchOnly              = $SearchOnly.IsPresent
}
