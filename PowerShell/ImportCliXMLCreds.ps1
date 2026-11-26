<#
.SYNOPSIS
    Exports or imports a credential using PowerShell CLIXML protection.
.DESCRIPTION
    On Windows, the exported credential can normally be decrypted only by the same user on the same computer.
    On non-Windows platforms, CLIXML does not provide equivalent OS-backed secrecy; protect the file permissions.
#>

[CmdletBinding(DefaultParameterSetName = 'Import')]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory, ParameterSetName = 'Export')]
    [switch]$Export,

    [Parameter(ParameterSetName = 'Export')]
    [pscredential]$Credential
)

if ($Export) {
    if (-not $Credential) {
        throw 'Supply -Credential when exporting.'
    }
    if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
        $Credential | Export-Clixml -LiteralPath $Path -Depth 2 -ErrorAction Stop
    }
    else {
        $destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $temporary = Join-Path ([IO.Path]::GetDirectoryName($destination)) ([IO.Path]::GetRandomFileName())
        $options = [IO.FileStreamOptions]@{
            Mode           = 'CreateNew'
            Access         = 'Write'
            Share          = 'None'
            UnixCreateMode = [IO.UnixFileMode]'UserRead, UserWrite'
        }
        $stream = [IO.File]::Open($temporary, $options)
        try {
            try {
                $xml = [Management.Automation.PSSerializer]::Serialize($Credential, 2)
                $bytes = [Text.Encoding]::UTF8.GetBytes($xml)
                $stream.Write($bytes, 0, $bytes.Length)
            }
            finally { $stream.Dispose() }
            [IO.File]::Move($temporary, $destination, $true)
        }
        finally { [IO.File]::Delete($temporary) }
    }
    Get-Item -LiteralPath $Path
    return
}

$importedCredential = Import-Clixml -LiteralPath $Path
if ($importedCredential -isnot [pscredential]) {
    throw "'$Path' does not contain a PSCredential object."
}
$importedCredential
