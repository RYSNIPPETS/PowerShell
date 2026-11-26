<#
.SYNOPSIS
    Changes Microsoft Entra user principal names from a CSV file.
.DESCRIPTION
    The CSV must contain UserId and NewUserPrincipalName columns.
#>

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users

[CmdletBinding()]
param(    [string]$ClientId,
    [string]$CertificateThumbprint,

    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$Path,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$changes = @(Import-Csv -LiteralPath $Path)
if (-not $changes) { throw "No records were found in '$Path'." }
foreach ($change in $changes) {
    if (-not $change.UserId -or -not $change.NewUserPrincipalName) {
        throw 'Every CSV record must contain UserId and NewUserPrincipalName.'
    }
}

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
    foreach ($change in $changes) {
        Update-MgUser -UserId $change.UserId -UserPrincipalName $change.NewUserPrincipalName
        [pscustomobject]@{
            UserId               = $change.UserId
            NewUserPrincipalName = $change.NewUserPrincipalName
            Updated              = $true
        }
    }
}
finally {
    if ($ownsConnection) { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null }
}
