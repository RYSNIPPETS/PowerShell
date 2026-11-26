<#
.SYNOPSIS
    Lists members of SharePoint Online site groups with PnP.PowerShell.
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

    [string[]]$GroupName
)

if (-not $Tenant -or -not $CertificateThumbprint) { throw 'Supply -Tenant and -CertificateThumbprint for unattended PnP authentication.' }
$parameters = @{ Url = $SiteUrl.AbsoluteUri; Thumbprint = $CertificateThumbprint; ClientId = $ClientId }
if ($Tenant) { $parameters.Tenant = $Tenant }
Connect-PnPOnline @parameters

try {
    $groups = if ($GroupName) {
        foreach ($name in $GroupName) { Get-PnPGroup -Identity $name }
    }
    else {
        Get-PnPGroup
    }

    foreach ($group in $groups) {
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
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
