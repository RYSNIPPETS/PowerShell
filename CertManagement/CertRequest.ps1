<#
.SYNOPSIS
    Requests a certificate from an Active Directory Certificate Services enrollment endpoint.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Template,

    [Parameter(Mandatory)]
    [string[]]$DnsName,

    [uri]$Url,

    [pscredential]$Credential,

    [string]$CertStoreLocation = 'Cert:\LocalMachine\My',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ Template = $Template; DnsName = $DnsName; CertStoreLocation = $CertStoreLocation }
if ($Url) { $parameters.Url = $Url }
if ($Credential) { $parameters.Credential = $Credential }

Get-Certificate @parameters
