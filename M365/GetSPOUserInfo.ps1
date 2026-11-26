<#
.SYNOPSIS
    Retrieves SharePoint Online site users with PnP.PowerShell.
#>

#Requires -Version 7.4
#Requires -Modules PnP.PowerShell

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [uri]$SiteUrl,

    [Parameter(Mandatory)]
    [string]$ClientId,

    [string]$Tenant,

    [string]$CertificateThumbprint,

    [string]$LoginName,

    [string]$OutputPath
)

if (-not $Tenant -or -not $CertificateThumbprint) { throw 'Supply -Tenant and -CertificateThumbprint for unattended PnP authentication.' }
$connectParameters = @{ Url = $SiteUrl.AbsoluteUri; Thumbprint = $CertificateThumbprint; ClientId = $ClientId }
if ($Tenant) { $connectParameters.Tenant = $Tenant }
Connect-PnPOnline @connectParameters

try {
    $users = Get-PnPUser
    if ($LoginName) {
        $users = $users | Where-Object { $_.LoginName -eq $LoginName -or $_.Email -eq $LoginName }
    }

    $users = $users | Select-Object Id, Title, Email, LoginName, PrincipalType, IsSiteAdmin
    if ($OutputPath) {
        $users | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8NoBOM
        Get-Item -LiteralPath $OutputPath
    }
    else {
        $users
    }
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
