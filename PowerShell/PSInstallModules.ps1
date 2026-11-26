<#
.SYNOPSIS
    Installs or updates a curated set of PowerShell modules with PSResourceGet.
#>

#Requires -Version 7.4

[CmdletBinding()]
param(
    [string[]]$Name = @(
        'ActiveDirectoryDsc',
        'AWS.Tools.Common',
        'Az',
        'CertificateDsc',
        'ComputerManagementDsc',
        'ExchangeOnlineManagement',
        'Microsoft.Graph',
        'NetworkingDsc',
        'PnP.PowerShell',
        'PSScriptAnalyzer',
        'PSWindowsUpdate',
        'SqlServer',
        'SqlServerDsc',
        'VMware.PowerCLI'
    ),

    [switch]$TrustPSGallery,

    [switch]$UpdateExisting,

    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not (Get-Command Install-PSResource -ErrorAction SilentlyContinue)) {
    throw 'Microsoft.PowerShell.PSResourceGet is required and is included with supported PowerShell 7 releases.'
}

if ($TrustPSGallery) {
    Set-PSResourceRepository -Name PSGallery -Trusted
}

foreach ($moduleName in $Name | Sort-Object -Unique) {
    $installed = Get-InstalledPSResource -Name $moduleName -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if ($installed -and -not $UpdateExisting) {
        Write-Verbose "Skipping '$moduleName' because version $($installed.Version) is already installed."
        continue
    }

    if ($installed) {
        Update-PSResource -Name $moduleName -Scope $Scope -Repository PSGallery -TrustRepository -ErrorAction Stop
    }
    else {
        Install-PSResource -Name $moduleName -Scope $Scope -Repository PSGallery -TrustRepository -ErrorAction Stop
    }
}

Get-InstalledPSResource -Name $Name -ErrorAction SilentlyContinue |
    Sort-Object Name, Version
