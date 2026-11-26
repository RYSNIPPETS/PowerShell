<#
.SYNOPSIS
    Runs an NTDS semantic database analysis on a domain controller.
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$service = Get-Service -Name NTDS -ErrorAction Stop
$pending = [Collections.Generic.Queue[object]]::new()
$pending.Enqueue($service)
$running = [Collections.Generic.List[string]]::new()
$seen = @{}
while ($pending.Count) {
    $current = $pending.Dequeue()
    if ($seen.ContainsKey($current.Name)) { continue }
    $seen[$current.Name] = $true
    if ($current.Status -notin 'Running', 'Stopped') { throw "Unexpected service state for '$($current.Name)': $($current.Status)." }
    if ($current.Status -eq 'Running') {
        $running.Add($current.Name)
        foreach ($dependent in $current.DependentServices) { $pending.Enqueue($dependent) }
    }
}
try {
    if ($running.Count) { Stop-Service -Name NTDS -Force -Confirm:$false -ErrorAction Stop }
    & ntdsutil.exe 'activate instance ntds' 'semantic database analysis' 'verbose on' 'go' quit quit
    if ($LASTEXITCODE -ne 0) { throw "ntdsutil.exe failed with exit code $LASTEXITCODE." }
}
finally {
    $restoreErrors = foreach ($name in $running) {
        try { Start-Service -Name $name -Confirm:$false -ErrorAction Stop }
        catch { "$name - $($_.Exception.Message)" }
    }
    if ($restoreErrors) { throw "Service restoration failed: $($restoreErrors -join '; ')" }
}
