<#
.SYNOPSIS
    Opens or reuses a Microsoft Graph session for unattended operation.
#>

#Requires -Modules Microsoft.Graph.Authentication

[CmdletBinding()]
param(    [string]$ClientId,
    [string]$CertificateThumbprint,

    [Parameter(Mandatory)]
    [string]$TenantId,

    [switch]$UseDeviceCode
)

if ($UseDeviceCode) { throw 'Use a preauthenticated Graph context or an application certificate.' }
if ($ClientId -or $CertificateThumbprint) {
    if (-not ($TenantId -and $ClientId -and $CertificateThumbprint)) { throw 'Supply -TenantId, -ClientId and -CertificateThumbprint together.' }
    Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome -ErrorAction Stop | Out-Null
}
else {
    $context = Get-MgContext -ErrorAction Stop
    if (-not $context -or ($TenantId -and $context.TenantId -ne $TenantId)) { throw 'Provide application certificate parameters or connect to the requested Graph tenant before calling this script.' }
}

Get-MgContext
