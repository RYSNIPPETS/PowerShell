<#
.SYNOPSIS
    Runs another PowerShell script with administrator or root privileges.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$FilePath,

    [string[]]$ArgumentList,

    [switch]$Wait,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$resolvedPath = (Resolve-Path -LiteralPath $FilePath).Path
$isElevated = if ($IsWindows) {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}
else {
    (& id -u) -eq 0
}

if ($isElevated) {
    & $resolvedPath @ArgumentList
    return
}

$startInfo = [Diagnostics.ProcessStartInfo]::new()
if ($IsWindows) {
    throw 'Start the calling process with an elevated Windows token.'
}
elseif ($IsLinux -or $IsMacOS) {
    $startInfo.FileName = (Get-Command sudo -CommandType Application -ErrorAction Stop).Source
    $startInfo.UseShellExecute = $false
    $startInfo.ArgumentList.Add('-n')
    $startInfo.ArgumentList.Add((Join-Path $PSHOME 'pwsh'))
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}
foreach ($argument in @('-NoProfile', '-NonInteractive', '-File', $resolvedPath)) { $startInfo.ArgumentList.Add($argument) }
foreach ($argument in $ArgumentList) { $startInfo.ArgumentList.Add($argument) }
$process = [Diagnostics.Process]::Start($startInfo)

if ($Wait) {
    try {
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) { throw "Elevated script exited with code $($process.ExitCode)." }
    }
    finally { $process.Dispose() }
}
else {
    $process
}
