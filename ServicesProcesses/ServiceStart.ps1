<#
.SYNOPSIS
    Starts a Windows service and waits for it to reach the Running state.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 60,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$service = Get-Service -Name $Name -ErrorAction Stop
if ($service.Status -ne 'Running') {
    Start-Service -InputObject $service -ErrorAction Stop
    $service.WaitForStatus('Running', [timespan]::FromSeconds($TimeoutSeconds))
    $service.Refresh()
}

$service
