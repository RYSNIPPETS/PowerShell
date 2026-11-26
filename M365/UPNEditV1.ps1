<#
.SYNOPSIS
    Changes one Microsoft Entra user principal name with Microsoft Graph.
#>

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users

[CmdletBinding()]
param(    [string]$ClientId,
    [string]$CertificateThumbprint,

    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(Mandatory)]
    [string]$UserId,

    [Parameter(Mandatory)]
    [string]$NewUserPrincipalName,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

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
    Update-MgUser -UserId $UserId -UserPrincipalName $NewUserPrincipalName
    Get-MgUser -UserId $NewUserPrincipalName -Property Id, DisplayName, UserPrincipalName
}
finally {
    if ($ownsConnection) { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null }
}
