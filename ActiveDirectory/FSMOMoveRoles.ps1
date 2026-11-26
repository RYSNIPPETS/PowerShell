<#
.SYNOPSIS
    Transfers selected FSMO roles to a domain controller.
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

Move-ADDirectoryServerOperationMasterRole -Identity $Identity -OperationMasterRole $Role -Confirm:$false -PassThru
