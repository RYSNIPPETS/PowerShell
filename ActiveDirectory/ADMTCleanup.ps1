<#
.SYNOPSIS
    Removes ADMT agent remnants from a Windows computer.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$ServiceName = 'OnePointDomainAgent',

    [string]$ProcessName = 'admagnt',

    [string]$InstallPath = 'C:\Windows\ADMT',

    [string]$RegistryPath = 'HKLM:\Software\Microsoft\ADMT',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | ForEach-Object {
    $_ | Stop-Process -Force
}

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($service) {
    if ($service.Status -ne 'Stopped') { Stop-Service -Name $ServiceName -Force }
    & "$env:SystemRoot\System32\sc.exe" delete $ServiceName | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "sc.exe failed with exit code $LASTEXITCODE." }
}

foreach ($path in $RegistryPath, $InstallPath) {
    if ((Test-Path -LiteralPath $path)) {
        Remove-Item -LiteralPath $path -Recurse -Force
    }
}
