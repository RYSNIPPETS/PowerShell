<#
.SYNOPSIS
  Post-uninstall cleanup for Microsoft 365 Apps leftovers.

.EXAMPLE
  .\O365UninstallCleanUp.ps1
#>
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [switch] $Aggressive,   # removes extra cached folders if present
    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$ErrorActionPreference = 'Stop'
if (-not $IsWindows) { throw 'This script requires Windows.' }

# Stop services if any remain
$services = 'ClickToRunSvc', 'OfficeSvc', 'sftlist', 'osppsvc'
foreach ($svc in $services) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s -and $s.Status -ne 'Stopped') {
        Write-Host "Stopping service $svc..." -ForegroundColor Yellow

        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Set-Service  $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# Scheduled tasks (old updater tasks)
$tasks = @(
    '\Microsoft\Office\Office ClickToRun Service Monitor',
    '\Microsoft\Office\OfficeTelemetryAgentLogOn',
    '\Microsoft\Office\OfficeTelemetryAgentFallBack'
)
foreach ($t in $tasks) {
    if (Get-ScheduledTask -TaskPath ($t.Substring(0, $t.LastIndexOf('\') + 1)) -TaskName ($t.Split('\')[-1]) -ErrorAction SilentlyContinue) {
        Write-Host "Deleting scheduled task $t" -ForegroundColor Yellow

        Unregister-ScheduledTask -TaskPath ($t.Substring(0, $t.LastIndexOf('\') + 1)) -TaskName ($t.Split('\')[-1]) -Confirm:$false
    }
}

# Start menu and program files vestiges
$paths = @(
    "$env:ProgramFiles\Common Files\microsoft shared\ClickToRun",
    "$env:ProgramFiles\Microsoft Office",
    "$env:LOCALAPPDATA\Microsoft\Office",
    "$env:ProgramData\Microsoft\Office",
    "$env:ProgramData\Microsoft\ClickToRun"
)
if (${env:ProgramFiles(x86)}) {
    $paths += Join-Path ${env:ProgramFiles(x86)} 'Microsoft Office'
}
if ($Aggressive) {
    $paths += @("$env:LOCALAPPDATA\Microsoft\OneDrive\Update", "$env:LOCALAPPDATA\Microsoft\Teams\current")
}
foreach ($p in $paths) {
    if (Test-Path -LiteralPath $p) {
        Write-Host "Removing $p" -ForegroundColor Yellow

        Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Remove stale uninstall registry entries.
$reg = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
Get-ChildItem $reg -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty $_.PsPath } |
    Where-Object { $_.DisplayName -like '*Click-to-Run*' -or $_.DisplayName -like '*Microsoft 365*' } |
    ForEach-Object {
        try {
            Remove-Item $_.PSPath -Recurse -Force
            Write-Host "Cleaned uninstall key: $($_.DisplayName)" -ForegroundColor Green
        }
        catch { Write-Warning "Failed to clean uninstall key '$($_.PSPath)': $($_.Exception.Message)" }
    }

Write-Host "Cleanup completed." -ForegroundColor Green
