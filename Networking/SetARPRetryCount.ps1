<#
.SYNOPSIS
    Sets the Windows ARP retry count on local or remote computers.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('Name', 'Server')]
    [string[]]$ComputerName,

    [ValidateRange(0, 3)]
    [int]$RetryCount = 0,

    [pscredential]$Credential,

    [Parameter(DontShow)]
    [switch]$Confirm
)

process {
    $ConfirmPreference = 'None'
    if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

    foreach ($computer in $ComputerName) {
        $parameters = @{
            ComputerName = $computer
            ScriptBlock  = {
                param($Value)
                $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
                New-ItemProperty -Path $path -Name ArpRetryCount -Value $Value -PropertyType DWord -Force
            }
            ArgumentList = $RetryCount
        }
        if ($Credential) {
            $parameters.Credential = $Credential
        }
        Invoke-Command @parameters
    }
}
