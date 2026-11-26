<#
.SYNOPSIS
    Adds or removes a Microsoft 365 license with Microsoft Graph.
#>

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement, Microsoft.Graph.Users.Actions

[CmdletBinding()]
param(    [string]$ClientId,
    [string]$CertificateThumbprint,

    [Parameter(Mandatory)]
    [string]$UserId,

    [Parameter(Mandatory)]
    [ValidateSet('Add', 'Remove')]
    [string]$Action,

    [Parameter(Mandatory)]
    [string]$SkuPartNumber,

    [string]$TenantId,

    [switch]$UseDeviceCode,

    [switch]$PassThru,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if ($PassThru) { Import-Module Microsoft.Graph.Users -ErrorAction Stop }

if ($UseDeviceCode) { throw 'Use a preauthenticated Graph context or an application certificate.' }
$ownsConnection = $false
if ($ClientId -or $CertificateThumbprint) {
    if (-not ($TenantId -and $ClientId -and $CertificateThumbprint)) { throw 'Supply -TenantId, -ClientId and -CertificateThumbprint together.' }
    Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome -ErrorAction Stop | Out-Null
    $ownsConnection = $true
}
else {
    $context = Get-MgContext -ErrorAction Stop
    if (-not $context -or ($TenantId -and $context.TenantId -ne $TenantId)) { throw 'Provide application certificate parameters or connect to the requested Graph tenant before calling this script.' }
}

try {
    $skuMatches = @(Get-MgSubscribedSku -All | Where-Object SkuPartNumber -EQ $SkuPartNumber)
    if ($skuMatches.Count -ne 1) { throw "Expected one subscribed SKU named '$SkuPartNumber'; found $($skuMatches.Count)." }
    $sku = $skuMatches[0]

    if ($Action -eq 'Add') {
        Set-MgUserLicense -UserId $UserId -AddLicenses @(@{ SkuId = $sku.SkuId }) -RemoveLicenses @() -ErrorAction Stop | Out-Null
    }
    else {
        Set-MgUserLicense -UserId $UserId -AddLicenses @() -RemoveLicenses @($sku.SkuId) -ErrorAction Stop | Out-Null
    }

    if ($PassThru) {
        Get-MgUserLicenseDetail -UserId $UserId
    }
}
finally {
    if ($ownsConnection) { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null }
}
