<#
.SYNOPSIS
    Creates an ADMT Password Export Server encryption key.
.DESCRIPTION
    Supplies the key password through redirected standard input to a child process without a console.
    Versions of ADMT that require an interactive console cannot create the key unattended.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SourceDomain,

    [Parameter(Mandatory)]
    [string]$KeyFile,

    [securestring]$KeyPassword,

    [string]$AdmtPath = 'ADMT.exe',

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$admt = Get-Command $AdmtPath -ErrorAction Stop

if (-not $KeyPassword -or -not $KeyPassword.Length) { throw 'Supply a nonempty -KeyPassword.' }
$destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($KeyFile)
if ([IO.File]::Exists($destination)) { throw "Key file already exists: '$destination'." }
$keyDirectory = [IO.Path]::GetDirectoryName($destination)
$temporaryKey = Join-Path $keyDirectory ("{0}.pes" -f [guid]::NewGuid().ToString('N'))
$start = [Diagnostics.ProcessStartInfo]::new($admt.Source)
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
foreach ($argValue in 'key', '/Option:Create', "/SourceDomain:$SourceDomain", "/KeyFile:$temporaryKey", '/KeyPassword:*') {
    $start.ArgumentList.Add($argValue)
}
$process = [Diagnostics.Process]::Start($start)
try {
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()
    $buffer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($KeyPassword)
    try {
        for ($entry = 0; $entry -lt 2; $entry++) {
            for ($index = 0; $index -lt $KeyPassword.Length; $index++) {
                $character = [char][uint16]([Runtime.InteropServices.Marshal]::ReadInt16($buffer, 2 * $index) -band 65535)
                if ($character -in [char]13, [char]10) { throw 'Key passwords must fit on one input line.' }
                $process.StandardInput.Write($character)
            }
            $process.StandardInput.WriteLine()
        }
    }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($buffer); $process.StandardInput.Close() }
    if (-not $process.WaitForExit(60000)) { throw 'ADMT did not finish unattended within 60 seconds.' }
    if ($process.ExitCode -ne 0) { throw "ADMT did not accept unattended key creation (exit $($process.ExitCode))." }
    $created = Get-Item -LiteralPath $temporaryKey -ErrorAction Stop
    if (-not $created.Length) { throw 'ADMT produced an empty key file.' }
    [IO.File]::Move($temporaryKey, $destination)
}
finally {
    if (-not $process.HasExited) { $process.Kill(); $process.WaitForExit() }
    $process.Dispose()
    [IO.File]::Delete($temporaryKey)
}
Get-Item -LiteralPath $KeyFile
