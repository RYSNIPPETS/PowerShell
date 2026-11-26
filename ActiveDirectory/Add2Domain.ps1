<#
.SYNOPSIS
    Joins a Windows computer to an Active Directory domain.
.NOTES
    PowerShell 7 on Windows invokes the built-in Windows PowerShell 5.1 command in a local compatibility session.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$DomainName,

    [pscredential]$Credential,

    [string]$OUPath,

    [string]$ComputerName = $env:COMPUTERNAME,

    [switch]$Restart,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{ ComputerName = $ComputerName; DomainName = $DomainName; PassThru = $true; Force = $true; Restart = [bool]$Restart }
if ($Credential) { $parameters.Credential = $Credential }
if ($OUPath) { $parameters.OUPath = $OUPath }

if (-not $Credential) { throw 'Supply -Credential to join the domain.' }
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
