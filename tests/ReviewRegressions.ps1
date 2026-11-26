<#
.SYNOPSIS
    Runs local PowerShell regression checks for credentials, certificate export, network sampling and setup media.
.DESCRIPTION
    Uses a temporary directory, in-memory certificates and fixture commands. Run with pwsh -NoProfile -File tests/ReviewRegressions.ps1.
#>
#Requires -Version 7.5

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$scratch = [IO.Directory]::CreateTempSubdirectory('rysnippets-tests-').FullName

function Assert-Result {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

try {
    $fileScript = Join-Path $root 'FileManagement/CreateNewTextFile.ps1'
    $testFile = Join-Path $scratch 'confirmation.txt'
    $ConfirmPreference = 'Low'
    $null = & $fileScript -Path $testFile -Content 'fixture' -Confirm
    Assert-Result ([IO.File]::ReadAllText($testFile).Trim() -eq 'fixture') 'Explicit confirmation must run unattended.'
    $previewRejected = $false
    try { $null = & $fileScript -Path $testFile -Content 'unexpected' -Force -WhatIf }
    catch [Management.Automation.ParameterBindingException] { $previewRejected = $true }
    Assert-Result ($previewRejected -and [IO.File]::ReadAllText($testFile).Trim() -eq 'fixture') 'A retired preview argument must fail before any write.'
    $ConfirmPreference = 'None'

    if (-not $IsWindows) {
        $credentialPath = Join-Path $scratch 'test.xml'
        $secret = [guid]::NewGuid().ToString()
        $password = [securestring]::new()
        foreach ($character in $secret.ToCharArray()) { $password.AppendChar($character) }
        $credential = [pscredential]::new('fixture', $password)
        [IO.File]::WriteAllText($credentialPath, 'old')
        [IO.File]::SetUnixFileMode($credentialPath, [IO.UnixFileMode]'UserRead, UserWrite, GroupRead, OtherRead')
        $scriptPath = Join-Path $root 'PowerShell/ImportCliXMLCreds.ps1'
        $null = & $scriptPath -Export -Credential $credential -Path $credentialPath
        Assert-Result ([IO.File]::GetUnixFileMode($credentialPath) -eq [IO.UnixFileMode]'UserRead, UserWrite') 'Credential export must replace existing permissions with 0600.'
        $restored = & $scriptPath -Path $credentialPath
        Assert-Result ($restored.UserName -eq 'fixture' -and $restored.GetNetworkCredential().Password -ceq $secret) 'Credential round trip failed.'
    }

    & {
        $calls = [Collections.Generic.List[int]]::new()
        function Export-PfxCertificate {
            [CmdletBinding()]
            param([Parameter(ValueFromPipeline)]$Cert, $FilePath, [securestring]$Password, [switch]$Force)
            begin { $count = 0 }
            process {
                Assert-Result ($Cert.HasPrivateKey -and $FilePath -and $Password -and $Force) 'PFX export lost a certificate or parameter.'
                $count++
            }
            end { $calls.Add($count) }
        }
        # Only the pipeline contract is under test. The fixture does not access a key store.
        $certificates = for ($index = 0; $index -lt 2; $index++) {
            $fixture = [Security.Cryptography.X509Certificates.X509Certificate2]::new()
            Add-Member -InputObject $fixture -NotePropertyName HasPrivateKey -NotePropertyValue $true -Force
            $fixture
        }
        try {
            $certificates | & (Join-Path $root 'CertManagement/CertExportSelfSigned.ps1') -FilePath (Join-Path $scratch 'export.pfx') -Password ([securestring]::new()) -Confirm:$false
            Assert-Result ($calls.Count -eq 1 -and $calls[0] -eq 2) 'Expected one PFX export containing both certificates.'
        }
        finally { foreach ($certificate in $certificates) { $certificate.Dispose() } }
    }

    & {
        $counters = @{ Sample = 0 }
        function Get-NetAdapter {
            param([switch]$Physical)
            [pscustomobject]@{ Name = 'fixture'; Status = 'Up'; Physical = $Physical }
        }
        function Get-NetAdapterStatistics {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'The fixture implements the Windows Get-NetAdapterStatistics command.')]
            param($Name)
            $counters.Sample++
            [pscustomobject]@{ Name = $Name[0]; ReceivedBytes = $counters.Sample * 100000; SentBytes = $counters.Sample * 100000 }
        }
        $json = & (Join-Path $root 'Networking/GetNetBandwidth.ps1') -As Json -Timeline -IntervalSeconds 0.02 -DurationSeconds 0.02
        $result = $json | ConvertFrom-Json
        Assert-Result (@($result.Summary).Count -eq 1 -and $result.Summary.Name -eq 'fixture') 'Single-adapter sampling failed.'
        $row = $result.Summary[0]
        Assert-Result ($row.Rx_Avg_Mbps -gt 0 -and [math]::Abs($row.Total_Avg_Mbps - $row.Rx_Avg_Mbps - $row.Tx_Avg_Mbps) -lt 0.002) 'Total bandwidth must include both receive and transmit rates.'
        Assert-Result ($row.Total_Peak_Mbps -eq $result.Timeline.Total_Mbps) 'Peak bandwidth must use the simultaneous interval total.'
    }

    $setup = Join-Path $root 'DeploymentLicensing/Server2025UnattendedVM.ps1'
    $xmlFile = & $setup -OutputDirectory $scratch -Confirm:$false
    [xml]$answer = Get-Content -LiteralPath $xmlFile.FullName -Raw
    Assert-Result ($answer.DocumentElement.LocalName -eq 'unattend' -and $null -eq $answer.SelectSingleNode("//*[local-name()='AdministratorPassword' or local-name()='AutoLogon']")) 'Setup answer file contains credentials or has the wrong root element.'

    'Review regression checks passed.'
}
finally { [IO.Directory]::Delete($scratch, $true) }
