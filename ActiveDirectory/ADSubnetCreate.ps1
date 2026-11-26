<#
.SYNOPSIS
    Creates an Active Directory replication subnet.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F:.]+/\d+$')]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Site,

    [string]$Description,

    [string]$Location,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ Name = $Name; Site = $Site }
if ($Description) { $parameters.Description = $Description }
if ($Location) { $parameters.Location = $Location }

New-ADReplicationSubnet @parameters -PassThru
