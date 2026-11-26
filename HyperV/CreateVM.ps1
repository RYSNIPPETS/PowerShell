<#
.SYNOPSIS
    Creates a generation 2 Hyper-V virtual machine with a new VHDX.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$VhdPath,

    [ValidateRange(1, 1048576)]
    [int]$VhdSizeGB = 60,

    [ValidateRange(1, 1048576)]
    [int]$StartupMemoryGB = 4,

    [Parameter(Mandatory)]
    [string]$SwitchName,

    [string]$ComputerName,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$parameters = @{
    Name               = $Name
    Path               = $Path
    NewVHDPath         = $VhdPath
    NewVHDSizeBytes    = $VhdSizeGB * 1GB
    MemoryStartupBytes = $StartupMemoryGB * 1GB
    BootDevice         = 'VHD'
    Generation         = 2
    SwitchName         = $SwitchName
}
if ($ComputerName) { $parameters.ComputerName = $ComputerName }

New-VM @parameters
