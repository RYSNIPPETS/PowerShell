<#
.SYNOPSIS
    Creates a self-signed certificate in a Windows certificate store.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$DnsName,

    [string]$FriendlyName = 'PowerShell Automation',

    [ValidateRange(1, 120)]
    [int]$ValidMonths = 24,

    [string]$CertStoreLocation = 'Cert:\LocalMachine\My',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$subject = 'CN={0}' -f $DnsName[0]

New-SelfSignedCertificate -DnsName $DnsName -Subject $subject -FriendlyName $FriendlyName -NotAfter (Get-Date).AddMonths($ValidMonths) -CertStoreLocation $CertStoreLocation
