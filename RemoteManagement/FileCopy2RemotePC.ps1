<#
.SYNOPSIS
    Copies a file or directory to the administrative share on remote Windows computers.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ComputerListPath,

    [Parameter(Mandatory)]
    [string]$SourcePath,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z]:\\')]
    [string]$DestinationPath,

    [switch]$Recurse,

    [switch]$Force,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$computers = Get-Content -LiteralPath $ComputerListPath |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith('#') }

foreach ($computer in $computers) {
    $drive = $DestinationPath.Substring(0, 1)
    $relativePath = $DestinationPath.Substring(3)
    $remotePath = "\\$computer\$drive`$\$relativePath"

    Copy-Item -LiteralPath $SourcePath -Destination $remotePath -Recurse:$Recurse -Force:$Force -ErrorAction Stop
}
