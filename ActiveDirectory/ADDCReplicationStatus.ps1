<#
.SYNOPSIS
    Retrieves Active Directory replication partner status and optionally starts synchronization.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$Target = (Get-ADDomain).DNSRoot,

    [switch]$Synchronize,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if ($Synchronize) {
    foreach ($controller in Get-ADDomainController -Filter *) {
        & repadmin.exe /syncall $controller.HostName /A /e /P | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Warning "Repadmin failed for '$($controller.HostName)' with exit code $LASTEXITCODE." }
    }
}

Get-ADReplicationPartnerMetadata -Target $Target -Scope Domain |
    Select-Object Server, Partner, Partition, LastReplicationAttempt, LastReplicationSuccess, LastReplicationResult, ConsecutiveReplicationFailures
