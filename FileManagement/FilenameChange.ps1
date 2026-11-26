<#
.SYNOPSIS
    Replaces characters in filenames in a directory.
#>

[CmdletBinding()]
param(
    [string]$Path = $PWD,

    [string]$Pattern = ' ',

    [string]$Replacement = '_',

    [switch]$Recurse,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

foreach ($file in Get-ChildItem -LiteralPath $Path -File -Recurse:$Recurse | Where-Object Name -Match $Pattern) {
    $newName = $file.Name -replace $Pattern, $Replacement

    Rename-Item -LiteralPath $file.FullName -NewName $newName
}
