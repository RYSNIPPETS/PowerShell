<#
.SYNOPSIS
    Moves an Active Directory object to another organizational unit.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [Parameter(Mandatory)]
    [string]$TargetPath,

    [string]$Server,

    [pscredential]$Credential,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ Identity = $Identity; TargetPath = $TargetPath }
if ($Server) { $parameters.Server = $Server }
if ($Credential) { $parameters.Credential = $Credential }

Move-ADObject @parameters -PassThru
