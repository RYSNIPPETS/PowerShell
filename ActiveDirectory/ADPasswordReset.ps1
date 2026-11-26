<#
.SYNOPSIS
    Resets an Active Directory user's password and optionally generates a temporary password.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(DefaultParameterSetName = 'Generate')]
param(
    [Parameter(Mandatory)]
    [string]$UserName,

    [Parameter(Mandatory, ParameterSetName = 'Supplied')]
    [securestring]$NewPassword,

    [Parameter(ParameterSetName = 'Generate')]
    [ValidateRange(12, 128)]
    [int]$GeneratedPasswordLength = 20,

    [bool]$ChangePasswordAtLogon = $true,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if ($PSCmdlet.ParameterSetName -eq 'Generate') {
    $characterSets = @(
        'ABCDEFGHJKLMNPQRSTUVWXYZ',
        'abcdefghijkmnopqrstuvwxyz',
        '23456789',
        '!@$%*-_=+?'
    )
    $characters = [Collections.Generic.List[char]]::new()
    foreach ($set in $characterSets) {
        $characters.Add($set[[Security.Cryptography.RandomNumberGenerator]::GetInt32($set.Length)])
    }
    $allCharacters = $characterSets -join ''
    while ($characters.Count -lt $GeneratedPasswordLength) {
        $characters.Add($allCharacters[[Security.Cryptography.RandomNumberGenerator]::GetInt32($allCharacters.Length)])
    }
    $shuffled = $characters | Sort-Object { [Security.Cryptography.RandomNumberGenerator]::GetInt32([int]::MaxValue) }
    $NewPassword = [securestring]::new()
    foreach ($character in $shuffled) { $NewPassword.AppendChar($character) }
    $NewPassword.MakeReadOnly()
}

Set-ADAccountPassword -Identity $UserName -NewPassword $NewPassword -Reset -Confirm:$false -ErrorAction Stop
$flagError = $null
try { Set-ADUser -Identity $UserName -ChangePasswordAtLogon $ChangePasswordAtLogon -Confirm:$false -ErrorAction Stop }
catch { $flagError = $_ }

[pscustomobject]@{
    UserName          = $UserName
    PasswordReset     = $true
    ChangeAtNextLogon = if (-not $flagError) { $ChangePasswordAtLogon }
    GeneratedPassword = if ($PSCmdlet.ParameterSetName -eq 'Generate') { $NewPassword }
    LogonFlagError    = if ($flagError) { $flagError.Exception.Message }
}
