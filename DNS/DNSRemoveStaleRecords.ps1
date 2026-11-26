<#
.SYNOPSIS
    Removes timestamped DNS records older than a specified age.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ZoneName,

    [string]$ComputerName = $env:COMPUTERNAME,

    [ValidateSet('A', 'AAAA', 'CNAME', 'PTR')]
    [string]$RecordType = 'A',

    [ValidateRange(1, 3650)]
    [int]$OlderThanDays = 14,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$records = Get-DnsServerResourceRecord -ComputerName $ComputerName -ZoneName $ZoneName -RRType $RecordType |
    Where-Object { $_.Timestamp -and $_.Timestamp -le $cutoff }

foreach ($record in $records) {
    Remove-DnsServerResourceRecord -ComputerName $ComputerName -ZoneName $ZoneName -InputObject $record -Force
}
