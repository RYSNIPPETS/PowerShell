<#
.SYNOPSIS
    Creates or replaces a CAA record set in Azure DNS.
#>

#Requires -Modules Az.Dns

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ZoneName,

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [string]$Name = '@',

    [Parameter(Mandatory)]
    [string[]]$CertificateAuthority,

    [mailaddress]$IncidentReportAddress,

    [ValidateRange(1, [int]::MaxValue)]
    [int]$Ttl = 3600,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$records = @($CertificateAuthority | ForEach-Object { New-AzDnsRecordConfig -CaaFlags 0 -CaaTag issue -CaaValue $_ })
if ($IncidentReportAddress) {
    $records += New-AzDnsRecordConfig -CaaFlags 0 -CaaTag iodef -CaaValue "mailto:$($IncidentReportAddress.Address)"
}

New-AzDnsRecordSet -Name $Name -RecordType CAA -ZoneName $ZoneName -ResourceGroupName $ResourceGroupName -Ttl $Ttl -DnsRecords $records -Overwrite
