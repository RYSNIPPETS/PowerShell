<#
.SYNOPSIS
    Adds a directory to PSModulePath without creating duplicate entries.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [ValidateSet('Process', 'User', 'Machine')]
    [string]$Target = $(if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') { 'User' } else { 'Process' }),

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$windowsPlatform = $IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop'
if (-not $windowsPlatform -and $Target -ne 'Process') { throw 'Unix supports only the Process environment target.' }
$expandedPath = [Environment]::ExpandEnvironmentVariables($Path)
$currentValue = [Environment]::GetEnvironmentVariable('PSModulePath', $Target)
$entries = @($currentValue -split [regex]::Escape([IO.Path]::PathSeparator) | Where-Object { $_ })

$comparer = if ($windowsPlatform) { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal }
$existingPaths = [Collections.Generic.HashSet[string]]::new([string[]]$entries, $comparer)
if (-not $existingPaths.Contains($expandedPath)) {
    $newValue = ($entries + $expandedPath) -join [IO.Path]::PathSeparator

    [Environment]::SetEnvironmentVariable('PSModulePath', $newValue, $Target)
}

[Environment]::GetEnvironmentVariable('PSModulePath', $Target)
