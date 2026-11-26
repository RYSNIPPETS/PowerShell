<#
.SYNOPSIS
    Reports and optionally deletes expired certificate files on Linux.
#>

#Requires -Version 7.5

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$SearchPath,

    [string[]]$Extension = @('.pem', '.crt', '.cer'),

    [datetime]$AsOf = (Get-Date),

    [switch]$Delete,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

if (-not $IsLinux) { throw 'This script requires Linux.' }

foreach ($directory in $SearchPath) {
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        Write-Warning "Directory '$directory' was not found."
        continue
    }
    foreach ($file in Get-ChildItem -LiteralPath $directory -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object Extension -In $Extension) {
        try {
            $bytes = [IO.File]::ReadAllBytes($file.FullName)
            $certificate = [Security.Cryptography.X509Certificates.X509CertificateLoader]::LoadCertificate($bytes)
            try {
                $notAfter = $certificate.NotAfter
                $singleCertificate = if ($bytes[0] -eq 0x30) {
                    $bytes.Length -eq $certificate.RawData.Length
                }
                else {
                    $pem = [Text.Encoding]::ASCII.GetString($bytes)
                    $pem -cmatch '\A\s*-----BEGIN CERTIFICATE-----[A-Za-z0-9+/=\s]+-----END CERTIFICATE-----\s*\z'
                }
            }
            finally { $certificate.Dispose() }
        }
        catch {
            Write-Warning "Unable to read '$($file.FullName)': $($_.Exception.Message)"
            continue
        }
        if (-not $singleCertificate) {
            Write-Warning "Skipping '$($file.FullName)' because it contains additional data."
            continue
        }
        if ($notAfter.ToUniversalTime() -ge $AsOf.ToUniversalTime()) { continue }

        $deleted = $false
        if ($Delete) {
            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
            $deleted = $true
        }
        [pscustomobject]@{ FilePath = $file.FullName; NotAfter = $notAfter; Deleted = $deleted }
    }
}
