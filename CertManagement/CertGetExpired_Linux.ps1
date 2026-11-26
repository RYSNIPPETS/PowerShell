<#
.SYNOPSIS
    Finds expired PEM or DER certificate files on Linux.
#>

#Requires -Version 7.5

[CmdletBinding()]
param(
    [string[]]$Path = @(
        '/etc/ssl/certs',
        '/etc/pki/tls/certs',
        '/etc/pki/ca-trust/extracted/pem',
        '/usr/local/share/ca-certificates',
        '/usr/share/ca-certificates'
    ),

    [string[]]$Extension = @('.crt', '.pem', '.cer'),

    [datetime]$AsOf = (Get-Date)
)

if (-not $IsLinux) {
    throw 'This script requires Linux.'
}
$files = foreach ($directory in $Path) {
    if (Test-Path -LiteralPath $directory -PathType Container) {
        Get-ChildItem -LiteralPath $directory -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object Extension -In $Extension
    }
}

foreach ($file in $files | Sort-Object FullName -Unique) {
    $certificates = [Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()
    try {
        $bytes = [IO.File]::ReadAllBytes($file.FullName)
        if ($bytes.Length -and $bytes[0] -eq 0x30) {
            $null = $certificates.Add([Security.Cryptography.X509Certificates.X509CertificateLoader]::LoadCertificate($bytes))
        }
        else {
            $certificates.ImportFromPem([Text.Encoding]::ASCII.GetString($bytes))
            if (-not $certificates.Count) { throw 'No PEM certificate found.' }
        }
        foreach ($certificate in $certificates) {
            if ($certificate.NotAfter.ToUniversalTime() -lt $AsOf.ToUniversalTime()) {
                [pscustomobject]@{
                    Subject  = $certificate.Subject
                    Issuer   = $certificate.Issuer
                    Serial   = $certificate.SerialNumber
                    NotAfter = $certificate.NotAfter
                    FilePath = $file.FullName
                }
            }
        }
    }
    catch { Write-Warning "Unable to read '$($file.FullName)': $($_.Exception.Message)" }
    finally { foreach ($certificate in $certificates) { $certificate.Dispose() } }
}
