<#
.SYNOPSIS
    Tests and optionally repairs the local computer's domain secure channel.
.NOTES
    PowerShell 7 on Windows invokes the built-in Windows PowerShell 5.1 command in a local compatibility session.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$Server,

    [pscredential]$Credential,

    [switch]$Repair,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{}
if ($Server) { $parameters.Server = $Server }
if ($Credential) { $parameters.Credential = $Credential }
$parameters.Repair = [bool]$Repair
$parameters.Verbose = $true

if ($PSVersionTable.PSEdition -eq 'Desktop') {
    Test-ComputerSecureChannel @parameters -ErrorAction Stop
    return
}
if (-not $IsWindows) { throw 'This script requires Windows.' }
$session = New-PSSession -UseWindowsPowerShell -ErrorAction Stop
try {
    Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock {
        $options = $using:parameters
        Test-ComputerSecureChannel @options -ErrorAction Stop
    }
}
finally {
    Remove-PSSession -Session $session
}
