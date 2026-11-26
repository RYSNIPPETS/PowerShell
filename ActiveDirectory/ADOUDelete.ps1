<#
.SYNOPSIS
    Deletes an Active Directory organizational unit.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [switch]$Recursive,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$server = (Get-ADDomainController -Discover -Writable -ErrorAction Stop).HostName | Select-Object -First 1
$ou = Get-ADOrganizationalUnit -Server $server -Identity $Identity -Properties ProtectedFromAccidentalDeletion -ErrorAction Stop

$deleted = $false
try {
    if ($ou.ProtectedFromAccidentalDeletion) {
        Set-ADOrganizationalUnit -Server $server -Identity $ou.ObjectGUID -ProtectedFromAccidentalDeletion $false -Confirm:$false -ErrorAction Stop
    }
    Remove-ADOrganizationalUnit -Server $server -Identity $ou.ObjectGUID -Recursive:$Recursive -Confirm:$false -ErrorAction Stop
    $deleted = $true
}
finally {
    if ($ou.ProtectedFromAccidentalDeletion -and -not $deleted) {
        try {
            Set-ADOrganizationalUnit -Server $server -Identity $ou.ObjectGUID -ProtectedFromAccidentalDeletion $true -Confirm:$false -ErrorAction Stop
        }
        catch { Write-Warning "Could not confirm protection was restored on '$($ou.ObjectGUID)' at '$server': $($_.Exception.Message)" }
    }
}
