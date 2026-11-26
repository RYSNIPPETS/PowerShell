<#
.SYNOPSIS
    Reports accounts whose passwords never expire and can clear that setting.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$SearchBase,

    [string]$ExportPath,

    [switch]$DisableNeverExpire,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ PasswordNeverExpires = $true; UsersOnly = $true; ErrorAction = 'Stop' }
if ($SearchBase) { $parameters.SearchBase = $SearchBase }
$users = @(Search-ADAccount @parameters |
        Get-ADUser -Properties PasswordExpired, PasswordNeverExpires, LastLogonDate)

$report = $users | Select-Object SamAccountName, Name, DistinguishedName, Enabled, PasswordExpired, PasswordNeverExpires, LastLogonDate
if ($ExportPath) {
    $directory = Split-Path -Path $ExportPath -Parent
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $report | Export-Csv -LiteralPath $ExportPath -NoTypeInformation -Encoding utf8NoBOM
}

if ($DisableNeverExpire) {
    foreach ($user in $users) {
        Set-ADUser -Identity $user -PasswordNeverExpires $false -ErrorAction Stop
    }
}

$report
