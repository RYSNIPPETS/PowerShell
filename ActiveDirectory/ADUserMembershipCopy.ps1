<#
.SYNOPSIS
    Copies Active Directory group memberships from one user to one or more destination users.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SourceUser,

    [Parameter(Mandatory)]
    [string[]]$DestinationUser,

    [string]$Server,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{}
if ($Server) { $parameters.Server = $Server }
$source = Get-ADUser -Identity $SourceUser @parameters
$groups = @(Get-ADPrincipalGroupMembership -Identity $source @parameters)

foreach ($destinationName in $DestinationUser) {
    $destination = Get-ADUser -Identity $destinationName @parameters
    $currentGroupDns = @(Get-ADPrincipalGroupMembership -Identity $destination @parameters | Select-Object -ExpandProperty DistinguishedName)
    foreach ($group in $groups | Where-Object DistinguishedName -NotIn $currentGroupDns) {
        Add-ADGroupMember -Identity $group -Members $destination @parameters
    }
}
