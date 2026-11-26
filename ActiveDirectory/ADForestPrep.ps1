<#
.SYNOPSIS
    Runs the supported ADPrep stages and optionally raises the forest functional level.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('ForestPrep', 'DomainPrep', 'GroupPolicyPrep')]
    [string[]]$Stage,

    [string]$AdPrepPath = 'adprep.exe',

    [string]$ForestIdentity,

    [ValidateSet('Windows2012Forest', 'Windows2012R2Forest', 'Windows2016Forest')]
    [string]$ForestMode,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$adprep = Get-Command $AdPrepPath -ErrorAction Stop
foreach ($item in $Stage) {
    $arguments = switch ($item) {
        'ForestPrep' { @('/forestprep') }
        'DomainPrep' { @('/domainprep') }
        'GroupPolicyPrep' { @('/domainprep', '/gpprep') }
    }

    & $adprep.Source @arguments
    if ($LASTEXITCODE -ne 0) { throw "ADPrep $item failed with exit code $LASTEXITCODE." }
}

if ($ForestMode) {
    if (-not $ForestIdentity) { $ForestIdentity = (Get-ADForest).Name }

    Set-ADForestMode -Identity $ForestIdentity -ForestMode $ForestMode
}
