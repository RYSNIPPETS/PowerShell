<#
.SYNOPSIS
    Seizes selected FSMO roles on a domain controller.
.DESCRIPTION
    Only use seizure when the previous role holder will never return to the domain.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [ValidateSet('SchemaMaster', 'DomainNamingMaster', 'PDCEmulator', 'RIDMaster', 'InfrastructureMaster')]
    [string[]]$Role = @('SchemaMaster', 'DomainNamingMaster', 'PDCEmulator', 'RIDMaster', 'InfrastructureMaster'),

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Move-ADDirectoryServerOperationMasterRole -Identity $Identity -OperationMasterRole $Role -Force -Confirm:$false -PassThru
