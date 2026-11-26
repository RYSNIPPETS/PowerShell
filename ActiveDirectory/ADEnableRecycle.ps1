<#
.SYNOPSIS
    Enables the Active Directory Recycle Bin optional feature.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$ForestName = (Get-ADForest).Name,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $ForestName -Confirm:$false
