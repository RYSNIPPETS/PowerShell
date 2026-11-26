<#
.SYNOPSIS
    Removes DNS records that reference a decommissioned domain controller.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ZoneName,

    [Parameter(Mandatory)]
    [string]$DomainControllerName,

    [ipaddress]$IPAddress,

    [string]$ComputerName = $env:COMPUTERNAME,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$normalizedName = $DomainControllerName.TrimEnd('.') + '.'
$records = Get-DnsServerResourceRecord -ComputerName $ComputerName -ZoneName $ZoneName
foreach ($record in $records) {
    $recordValues = @($record.RecordData.PSObject.Properties.Value | ForEach-Object { $_.ToString() })
    $matchesName = $recordValues -contains $normalizedName -or $recordValues -contains $DomainControllerName.TrimEnd('.')
    $matchesAddress = $IPAddress -and $recordValues -contains $IPAddress.IPAddressToString
    if (-not ($matchesName -or $matchesAddress)) { continue }

    Remove-DnsServerResourceRecord -ComputerName $ComputerName -ZoneName $ZoneName -InputObject $record -Force
}
