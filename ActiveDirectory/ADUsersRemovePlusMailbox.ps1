<#
.SYNOPSIS
    Deprovisions an Active Directory user and optional on-premises Exchange/file resources.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [string[]]$UserDataRoot,

    [string]$ProfileScriptRoot,

    [switch]$DisableMailbox,

    [switch]$RemoveAdUser,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$user = Get-ADUser -Identity $Identity -ErrorAction Stop
$targets = [Collections.Generic.List[string]]::new()

function Get-DataDirectory {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($item -isnot [IO.DirectoryInfo]) { throw "Expected a filesystem directory at '$Path'." }
    $item.FullName
}

foreach ($root in $UserDataRoot) {
    $targets.Add((Join-Path -Path (Get-DataDirectory $root) -ChildPath $user.SamAccountName))
}
if ($ProfileScriptRoot) {
    $targets.Add((Join-Path -Path (Get-DataDirectory $ProfileScriptRoot) -ChildPath "$($user.SamAccountName).xml"))
}

if ($DisableMailbox) {
    $null = Get-Command Disable-Mailbox -ErrorAction Stop
    $mailbox = Get-Mailbox -Identity $user.DistinguishedName -ErrorAction Stop
    if (-not $mailbox) { throw "No mailbox found for '$($user.DistinguishedName)'." }
}
if ($RemoveAdUser) { $null = Get-Command Remove-ADUser -ErrorAction Stop }
$existingTargets = foreach ($target in $targets) {
    if (Test-Path -LiteralPath $target -ErrorAction Stop) { $target }
}

$completed = [Collections.Generic.List[string]]::new()
try {
    if ($DisableMailbox) {
        Disable-Mailbox -Identity $user.DistinguishedName -Confirm:$false -ErrorAction Stop
        $completed.Add("Disabled mailbox for $($user.DistinguishedName)")
        Write-Information "Disabled mailbox for $($user.DistinguishedName)." -InformationAction Continue
    }
    foreach ($target in $existingTargets) {
        Remove-Item -LiteralPath $target -Recurse -Force -Confirm:$false -ErrorAction Stop
        $completed.Add("Removed $target")
        Write-Information "Removed $target." -InformationAction Continue
    }

    if ($RemoveAdUser) {
        Remove-ADUser -Identity $user -Confirm:$false -ErrorAction Stop
        $completed.Add("Removed AD user $($user.DistinguishedName)")
    }
}
catch {
    $completedSteps = if ($completed.Count) { $completed -join ', ' } else { 'none' }
    throw "Offboarding failed for '$Identity': $($_.Exception.Message) Completed steps: $completedSteps."
}

[pscustomobject]@{
    SamAccountName   = $user.SamAccountName
    CompletedSteps   = $completed.ToArray()
    DataTargets      = $targets.ToArray()
    MailboxRequested = $DisableMailbox.IsPresent
    RemovalRequested = $RemoveAdUser.IsPresent
}
