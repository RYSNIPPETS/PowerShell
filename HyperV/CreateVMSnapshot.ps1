<#
.SYNOPSIS
    Creates a Hyper-V checkpoint.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$VMName,

    [string]$SnapshotName = ('Manual checkpoint {0:yyyy-MM-dd HHmmss}' -f (Get-Date)),

    [string]$ComputerName,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ VMName = $VMName; SnapshotName = $SnapshotName }
if ($ComputerName) { $parameters.ComputerName = $ComputerName }

Checkpoint-VM @parameters
