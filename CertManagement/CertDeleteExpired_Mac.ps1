<#
.SYNOPSIS
    Reports and optionally deletes expired certificates from macOS keychains.
#>

#Requires -Version 7.1

[CmdletBinding()]
param(
    [string[]]$Keychain = @(
        (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Library/Keychains/login.keychain-db'),
        '/Library/Keychains/System.keychain'
    ),

    [datetime]$AsOf = (Get-Date),

    [switch]$Delete,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsMacOS) {
    throw 'This script requires macOS.'
}
$null = Get-Command security -CommandType Application -ErrorAction Stop

$results = [Collections.Generic.List[object]]::new()
foreach ($keychainPath in $Keychain) {
    if (-not (Test-Path -LiteralPath $keychainPath -PathType Leaf)) {
        Write-Warning "Keychain '$keychainPath' was not found."
        continue
    }

    $pemOutput = (& security find-certificate -a -p $keychainPath 2>$null) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not read keychain '$keychainPath'."
        continue
    }

    $certificateMatches = [regex]::Matches($pemOutput, '(?s)-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----')
    foreach ($match in $certificateMatches) {
        try {
            $certificate = [Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPem($match.Value)
            try {
                $notAfter = $certificate.NotAfter
                $subject = $certificate.Subject
                $issuer = $certificate.Issuer
                $thumbprint = $certificate.Thumbprint
            }
            finally { $certificate.Dispose() }
        }
        catch {
            Write-Warning "Unable to read a certificate in '$keychainPath': $($_.Exception.Message)"
            continue
        }
        if ($notAfter.ToUniversalTime() -ge $AsOf.ToUniversalTime()) { continue }
        $deleted = $false
        if ($Delete) {
            & security delete-certificate -Z $thumbprint $keychainPath
            if ($LASTEXITCODE -ne 0) { throw "Failed to delete certificate '$thumbprint' from '$keychainPath'." }
            $deleted = $true
        }

        $results.Add([pscustomobject]@{
                Keychain   = $keychainPath
                Subject    = $subject
                Issuer     = $issuer
                Thumbprint = $thumbprint
                NotAfter   = $notAfter
                Deleted    = $deleted
            })
    }
}

$results
