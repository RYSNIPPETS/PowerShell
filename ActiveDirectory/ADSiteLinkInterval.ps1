<#
.SYNOPSIS
    Sets an Active Directory site-link replication interval.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$Identity = 'DEFAULTIPSITELINK',

    [Parameter(Mandatory)]
    [ValidateRange(15, 10080)]
    [int]$Minutes,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Set-ADReplicationSiteLink -Identity $Identity -ReplicationFrequencyInMinutes $Minutes -PassThru
