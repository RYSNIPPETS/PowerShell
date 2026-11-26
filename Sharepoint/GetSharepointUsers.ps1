<#
.SYNOPSIS
    Exports SharePoint Online users and group memberships with PnP.PowerShell.
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

    [string]$OutputPath
)

if (-not $Tenant -or -not $CertificateThumbprint) { throw 'Supply -Tenant and -CertificateThumbprint for unattended PnP authentication.' }
$parameters = @{ Url = $SiteUrl.AbsoluteUri; Thumbprint = $CertificateThumbprint; ClientId = $ClientId }
if ($Tenant) { $parameters.Tenant = $Tenant }
Connect-PnPOnline @parameters

try {
    $results = foreach ($group in Get-PnPGroup) {
        foreach ($member in Get-PnPGroupMember -Group $group) {
            [pscustomobject]@{
                SiteUrl       = $SiteUrl.AbsoluteUri
                GroupName     = $group.Title
                DisplayName   = $member.Title
                LoginName     = $member.LoginName
                Email         = $member.Email
                PrincipalType = $member.PrincipalType
            }
        }
    }

    if ($OutputPath) {
        $results | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8NoBOM
    }
    $results
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
