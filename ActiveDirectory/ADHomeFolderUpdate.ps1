<#
.SYNOPSIS
    Sets Active Directory home-directory paths for selected users.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$HomeDirectoryRoot,

    [ValidatePattern('^[A-Za-z]:$')]
    [string]$HomeDrive = 'H:',

    [string]$SearchBase,

    [string[]]$Identity,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$users = if ($Identity) {
    $Identity | ForEach-Object { Get-ADUser -Identity $_ }
}
else {
    $parameters = @{ Filter = '*' }
    if ($SearchBase) { $parameters.SearchBase = $SearchBase }
    Get-ADUser @parameters
}

foreach ($user in $users) {
    $homeDirectory = Join-Path $HomeDirectoryRoot $user.SamAccountName

    Set-ADUser -Identity $user -HomeDirectory $homeDirectory -HomeDrive $HomeDrive
}
