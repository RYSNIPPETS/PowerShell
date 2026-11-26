<#
.SYNOPSIS
    Sets an Active Directory replication subnet description.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Description,

    [string]$Server,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ Identity = $Identity; Description = $Description }
if ($Server) { $parameters.Server = $Server }

Set-ADReplicationSubnet @parameters -PassThru
