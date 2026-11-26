<#
.SYNOPSIS
    Reports and optionally enables organization-wide mailbox auditing.
#>

#Requires -Modules ExchangeOnlineManagement

[CmdletBinding()]
param(    [string]$AppId,
    [string]$CertificateThumbprint,
    [string]$Organization,

    [string]$UserPrincipalName,

    [switch]$UseDeviceAuthentication,

    [switch]$EnsureEnabled,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if ($UseDeviceAuthentication -or $UserPrincipalName -or -not ($AppId -and $CertificateThumbprint -and $Organization)) {
    throw 'Supply -Organization, -AppId and -CertificateThumbprint for unattended authentication.'
}

$connectParameters = @{ AppId = $AppId; CertificateThumbprint = $CertificateThumbprint; Organization = $Organization; ShowBanner = $false }
Connect-ExchangeOnline @connectParameters

try {
    $organization = Get-OrganizationConfig
    if ($EnsureEnabled -and $organization.AuditDisabled) {
        Set-OrganizationConfig -AuditDisabled:$false
        $organization = Get-OrganizationConfig
    }

    [pscustomobject]@{
        Organization    = $organization.Name
        AuditDisabled   = $organization.AuditDisabled
        DefaultAuditSet = $organization.DefaultAuditSet
    }
}
finally {
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
}
