<#
.SYNOPSIS
    Removes an AppX package from local users who are not administrators.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$administratorNames = @(Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop |
        ForEach-Object { ($_.Name -split '\\')[-1] })

foreach ($user in Get-LocalUser | Where-Object Enabled) {
    if ($user.Name -in $administratorNames) {
        Write-Verbose "Skipping administrator '$($user.Name)'."
        continue
    }

    $packages = @(Get-AppxPackage -User $user.Name -Name $Name -ErrorAction SilentlyContinue)
    foreach ($package in $packages) {
        Remove-AppxPackage -Package $package.PackageFullName -User $user.SID -ErrorAction Stop
    }
}
