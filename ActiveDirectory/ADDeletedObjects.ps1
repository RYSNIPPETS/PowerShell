<#
.SYNOPSIS
    Lists or restores deleted Active Directory objects.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$Identity,

    [string]$SearchBase,

    [switch]$Restore,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ IncludeDeletedObjects = $true; Properties = '*' }

if ($Identity) {
    $objects = @(Get-ADObject -Identity $Identity @parameters)
}
else {
    if ($SearchBase) { $parameters.SearchBase = $SearchBase }
    $objects = @(Get-ADObject -LDAPFilter '(isDeleted=TRUE)' @parameters)
}

if (-not $Restore) {
    $objects | Select-Object Name, ObjectClass, LastKnownParent, WhenChanged, DistinguishedName
    return
}

if (-not $Identity) { throw '-Identity is required when -Restore is specified.' }
foreach ($object in $objects) {
    $object | Restore-ADObject -PassThru
}
