<#
.SYNOPSIS
    Reports or stops an explicit list of non-default Windows services.
.DESCRIPTION
    Automatic classification of a service as safe to stop is unreliable. This version requires
    callers to supply the exact service names and performs no changes unless -Stop is specified.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$Name,

    [switch]$Stop,

    [switch]$Force,

    [ValidateRange(1, 600)]
    [int]$TimeoutSeconds = 90,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsWindows) { throw 'This script requires Windows.' }

$protectedServices = @('RpcSs', 'DcomLaunch', 'LSM', 'PlugPlay', 'Power', 'Wininit', 'Winlogon')
$services = foreach ($serviceName in $Name | Sort-Object -Unique) {
    if ([Management.Automation.WildcardPattern]::ContainsWildcardCharacters($serviceName)) {
        throw "Supply an exact service name: '$serviceName'."
    }
    Get-Service -Name $serviceName -ErrorAction Stop
}

$pending = [Collections.Generic.Queue[object]]::new()
foreach ($service in $services) { $pending.Enqueue($service) }
$seen = @{}
while ($pending.Count) {
    $service = $pending.Dequeue()
    if ($seen.ContainsKey($service.Name)) { continue }
    $seen[$service.Name] = $true
    if ($service.Name -in $protectedServices) { throw "Refusing to stop protected service '$($service.Name)'." }
    if ($Stop -and $Force) {
        foreach ($dependent in $service.DependentServices) {
            if ($dependent.Status -ne 'Stopped') { $pending.Enqueue($dependent) }
        }
    }
}

if ($Stop) {
    foreach ($service in $services | Where-Object Status -NE 'Stopped') {
        Stop-Service -InputObject $service -Force:$Force -ErrorAction Stop
        $service.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Stopped, [timespan]::FromSeconds($TimeoutSeconds))
    }
}

$services | ForEach-Object { Get-Service -Name $_.Name } |
    Select-Object Name, DisplayName, Status, StartType
