<#
.SYNOPSIS
    Creates or replaces a UTF-8 text file.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string[]]$Content,

    [switch]$Force,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if ((Test-Path -LiteralPath $Path) -and -not $Force) {
    throw "The file '$Path' already exists. Use -Force to replace it."
}

Set-Content -LiteralPath $Path -Value $Content -Encoding utf8 -Force:$Force
Get-Item -LiteralPath $Path
