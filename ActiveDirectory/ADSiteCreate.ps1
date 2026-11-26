<#
.SYNOPSIS
    Creates an Active Directory replication site.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [string]$Description,

    [string]$Server,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ Name = $Name }
if ($Description) { $parameters.Description = $Description }
if ($Server) { $parameters.Server = $Server }

New-ADReplicationSite @parameters -PassThru
