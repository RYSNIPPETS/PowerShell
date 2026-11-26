<#
.SYNOPSIS
    Creates an Active Directory organizational unit.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [string]$Path,

    [string]$Description,

    [bool]$ProtectedFromAccidentalDeletion = $true,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ Name = $Name; ProtectedFromAccidentalDeletion = $ProtectedFromAccidentalDeletion }
if ($Path) { $parameters.Path = $Path }
if ($Description) { $parameters.Description = $Description }

New-ADOrganizationalUnit @parameters -PassThru
