<#
.SYNOPSIS
    Installs Windows Server File and Storage Services.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string[]]$Name = @('File-Services'),

    [switch]$Restart,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Install-WindowsFeature -Name $Name -IncludeAllSubFeature -IncludeManagementTools -Restart:$Restart
