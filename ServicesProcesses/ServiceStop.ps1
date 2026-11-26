<#
.SYNOPSIS
    Stops a Windows service and waits for it to reach the Stopped state.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 60,

    [switch]$Force,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$service = Get-Service -Name $Name -ErrorAction Stop
if ($service.Status -ne 'Stopped') {
    Stop-Service -InputObject $service -Force:$Force -ErrorAction Stop
    $service.WaitForStatus('Stopped', [timespan]::FromSeconds($TimeoutSeconds))
    $service.Refresh()
}

$service
