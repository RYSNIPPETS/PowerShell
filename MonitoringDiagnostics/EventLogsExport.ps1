<#
.SYNOPSIS
    Exports a Windows event log from remote computers to a central directory.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('Name')]
    [string[]]$ComputerName,

    [string]$LogName = 'Application',

    [string]$RemoteDirectory = 'C:\Logs',

    [Parameter(Mandatory)]
    [string]$DestinationDirectory,

    [pscredential]$Credential,

    [Parameter(DontShow)]
    [switch]$Confirm
)

process {
    $ConfirmPreference = 'None'
    if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

    foreach ($computer in $ComputerName) {
        $safeLogName = $LogName -replace '[\\/:*?"<>|]', '_'
        $fileName = '{0}_{1}_{2}.evtx' -f $computer, $safeLogName, [guid]::NewGuid().ToString('N')

        $folder = New-Item -ItemType Directory -Path $DestinationDirectory -Force -ErrorAction Stop
        $destination = Join-Path $folder.FullName $fileName

        $remoteFolder = $RemoteDirectory
        $sessionParameters = @{ ComputerName = $computer }
        if ($Credential) {
            $sessionParameters.Credential = $Credential
        }
        $session = New-PSSession @sessionParameters -ErrorAction Stop
        try {
            $archive = Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock {
                $eventLogName = $using:LogName
                $directory = $using:remoteFolder
                $path = Join-Path $directory $using:fileName
                $null = New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop
                & wevtutil.exe epl $eventLogName $path /ow:true
                if ($LASTEXITCODE -ne 0) {
                    throw "wevtutil.exe failed with exit code $LASTEXITCODE."
                }
                Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop
            }
            $remotePath = $archive.Path
            try {
                Copy-Item -FromSession $session -LiteralPath $remotePath -Destination $destination -ErrorAction Stop
                if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256 -ErrorAction Stop).Hash -ne $archive.Hash) {
                    throw "SHA256 mismatch for '$destination'."
                }
            }
            catch { throw "Export retained on $computer at '$remotePath'. $($_.Exception.Message)" }
            Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock {
                Remove-Item -LiteralPath $using:remotePath -Force -ErrorAction Stop
            }
            Get-Item -LiteralPath $destination
        }
        finally {
            Remove-PSSession -Session $session
        }
    }
}
