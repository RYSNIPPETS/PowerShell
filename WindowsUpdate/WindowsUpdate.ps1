<#
.SYNOPSIS
    Scans for or installs Windows updates with PSWindowsUpdate.
.EXAMPLE
    ./WindowsUpdate.ps1
.EXAMPLE
    ./WindowsUpdate.ps1 -Install -AcceptAll -AutoReboot
#>

#Requires -RunAsAdministrator
#Requires -Modules PSWindowsUpdate

[CmdletBinding()]
param(
    [switch]$Install,

    [switch]$MicrosoftUpdate,

    [switch]$AcceptAll,

    [switch]$AutoReboot,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsWindows) {
    throw 'This script requires Windows.'
}
if (($AcceptAll -or $AutoReboot) -and -not $Install) {
    throw '-AcceptAll and -AutoReboot are valid only with -Install.'
}

if ($Install -and -not $AcceptAll) { throw 'Supply -AcceptAll to install updates unattended.' }

if ($MicrosoftUpdate) {
    Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
}

if (-not $Install) {
    Get-WindowsUpdate -MicrosoftUpdate:$MicrosoftUpdate
    return
}

$installOptions = @{ MicrosoftUpdate = [bool]$MicrosoftUpdate; Install = $true; AcceptAll = $true }
if ($AutoReboot) { $installOptions.AutoReboot = $true }
else { $installOptions.IgnoreReboot = $true }
Get-WindowsUpdate @installOptions
