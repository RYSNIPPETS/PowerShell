<#
.SYNOPSIS
    Replaces matching text in a text file.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$Pattern,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Replacement,

    [switch]$SimpleMatch,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$content = Get-Content -LiteralPath $Path -Raw
$updated = if ($SimpleMatch) {
    $content.Replace($Pattern, $Replacement)
}
else {
    $content -replace $Pattern, $Replacement
}

if ($content -ceq $updated) {
    Write-Verbose 'No matching text was found.'
    return
}

Set-Content -LiteralPath $Path -Value $updated -Encoding utf8 -NoNewline
