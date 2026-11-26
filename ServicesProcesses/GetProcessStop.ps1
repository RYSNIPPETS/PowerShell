<#
.SYNOPSIS
    Stops processes by name or process ID.
#>

[CmdletBinding(DefaultParameterSetName = 'Name')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Name')]
    [string[]]$Name,

    [Parameter(Mandatory, ParameterSetName = 'Id')]
    [int[]]$Id,

    [switch]$Force,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$processes = if ($PSCmdlet.ParameterSetName -eq 'Id') {
    Get-Process -Id $Id -ErrorAction Stop
}
else {
    Get-Process -Name $Name -ErrorAction Stop
}

foreach ($process in $processes) {
    $process | Stop-Process -Force:$Force
}
