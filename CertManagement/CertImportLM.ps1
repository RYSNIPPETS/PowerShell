<#
.SYNOPSIS
    Imports a certificate into a Windows certificate store.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$FilePath,

    [string]$CertStoreLocation = 'Cert:\LocalMachine\Root',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Import-Certificate -FilePath $FilePath -CertStoreLocation $CertStoreLocation
