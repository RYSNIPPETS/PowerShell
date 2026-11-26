<#
.SYNOPSIS
    Installs one or more Windows Server roles or features.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$Name,

    [string]$ComputerName = $env:COMPUTERNAME,

    [switch]$IncludeManagementTools,

    [switch]$Restart,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{
    Name                   = $Name
    IncludeManagementTools = $IncludeManagementTools
    Restart                = $Restart
}
if ($ComputerName -and $ComputerName -notin '.', 'localhost', $env:COMPUTERNAME) {
    $parameters.ComputerName = $ComputerName
}

Install-WindowsFeature @parameters
