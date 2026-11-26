<#
.SYNOPSIS
    Exports a certificate and private key to a password-protected PFX file.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

    [Parameter(Mandatory)]
    [string]$FilePath,

    [Parameter(Mandatory)]
    [securestring]$Password,

    [switch]$ChainOptionBuildChain,

    [Parameter(DontShow)]
    [switch]$Confirm
)

begin {
    $ConfirmPreference = 'None'
    if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }
    $certificates = [Collections.Generic.List[object]]::new()
}
process {
    if (-not $Certificate.HasPrivateKey) {
        throw "Certificate '$($Certificate.Thumbprint)' has no private key to export."
    }

    $certificates.Add($Certificate)
}
end {
    if ($certificates.Count) {
        $parameters = @{
            FilePath = $FilePath
            Password = $Password
            Force    = $true
        }
        if ($ChainOptionBuildChain) { $parameters.ChainOption = 'BuildChain' }
        $certificates | Export-PfxCertificate @parameters -ErrorAction Stop
    }
}
