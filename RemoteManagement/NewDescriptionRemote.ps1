<#
.SYNOPSIS
    Sets the Windows computer description on a remote computer.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$ComputerName,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Description,

    [pscredential]$Credential,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

foreach ($computer in $ComputerName) {
    $parameters = @{
        ComputerName = $computer
        ScriptBlock  = {
            param($NewDescription)
            Get-CimInstance -ClassName Win32_OperatingSystem |
                Set-CimInstance -Property @{ Description = $NewDescription }
        }
        ArgumentList = $Description
    }
    if ($Credential) {
        $parameters.Credential = $Credential
    }
    Invoke-Command @parameters
}
