<#
.SYNOPSIS
    Sets an Active Directory replication site location.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Location,

    [string]$Server,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ Identity = $Identity; Location = $Location }
if ($Server) { $parameters.Server = $Server }

Set-ADReplicationSite @parameters -PassThru
