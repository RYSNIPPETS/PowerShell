<#
.SYNOPSIS
    Moves a Windows computer from its current domain to a target domain.
.NOTES
    PowerShell 7 on Windows invokes the built-in Windows PowerShell 5.1 command in a local compatibility session.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [string]$TargetDomainName,

    [Parameter(Mandatory)]
    [pscredential]$TargetDomainCredential,

    [Parameter(Mandatory)]
    [pscredential]$SourceDomainCredential,

    [string]$TargetDomainController,

    [string]$TargetOUPath,

    [switch]$Restart,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{
    ComputerName           = $ComputerName
    DomainName             = $TargetDomainName
    Credential             = $TargetDomainCredential
    UnjoinDomainCredential = $SourceDomainCredential
    PassThru               = $true
    Force                  = $true
    Restart                = [bool]$Restart
}
if ($TargetDomainController) { $parameters.Server = $TargetDomainController }
if ($TargetOUPath) { $parameters.OUPath = $TargetOUPath }

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    Add-Computer @parameters -ErrorAction Stop
    return
}
if (-not $IsWindows) { throw 'This script requires Windows.' }
$session = New-PSSession -UseWindowsPowerShell -ErrorAction Stop
try {
    Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock {
        $options = $using:parameters
        Add-Computer @options -ErrorAction Stop
    }
}
finally {
    Remove-PSSession -Session $session
}
