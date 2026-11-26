<#
.SYNOPSIS
    Configures the daily replication window for an Active Directory site link.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$Identity = 'DEFAULTIPSITELINK',

    [ValidateRange(0, 23)]
    [int]$StartHour = 8,

    [ValidateRange(0, 23)]
    [int]$EndHour = 17,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$schedule = [DirectoryServices.ActiveDirectory.ActiveDirectorySchedule]::new()
$schedule.SetDailySchedule(
    [DirectoryServices.ActiveDirectory.HourOfDay]$StartHour,
    [DirectoryServices.ActiveDirectory.MinuteOfHour]::Zero,
    [DirectoryServices.ActiveDirectory.HourOfDay]$EndHour,
    [DirectoryServices.ActiveDirectory.MinuteOfHour]::Zero
)

Set-ADReplicationSiteLink -Identity $Identity -ReplicationSchedule $schedule -PassThru
