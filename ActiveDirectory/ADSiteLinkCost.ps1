<#
.SYNOPSIS
    Sets an Active Directory site-link cost.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$Identity = 'DEFAULTIPSITELINK',

    [Parameter(Mandatory)]
    [ValidateRange(1, 99999)]
    [int]$Cost,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Set-ADReplicationSiteLink -Identity $Identity -Cost $Cost -PassThru
