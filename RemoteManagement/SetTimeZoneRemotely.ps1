<#
.SYNOPSIS
    Sets the Windows time zone on one or more remote computers.
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('Name')]
    [string[]]$ComputerName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TimeZoneId,

    [pscredential]$Credential,

    [Parameter(DontShow)]
    [switch]$Confirm
)

begin {
    $ConfirmPreference = 'None'
    if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

    if (-not $IsWindows) {
        throw 'This script requires Windows.'
    }
}

process {
    $targets = if ($ComputerName) {
        $ComputerName
    }
    else {
        if (-not (Get-Command Get-ADComputer -ErrorAction SilentlyContinue)) {
            throw 'Supply -ComputerName or install/import the ActiveDirectory module.'
        }
        Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
    }

    foreach ($computer in $targets) {
        $parameters = @{ ComputerName = $computer; ErrorAction = 'Stop' }
        if ($Credential) { $parameters.Credential = $Credential }
        $requestedTimeZone = $TimeZoneId
        Invoke-Command @parameters -ScriptBlock {
            Set-TimeZone -Id $using:requestedTimeZone -PassThru
        }
    }
}
