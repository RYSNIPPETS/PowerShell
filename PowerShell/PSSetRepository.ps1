<#
.SYNOPSIS
    Sets the trusted state of a PSResourceGet repository.
#>

[CmdletBinding()]
param(
    [string]$Name = 'PSGallery',

    [bool]$Trusted = $true,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

Set-PSResourceRepository -Name $Name -Trusted:$Trusted -PassThru
