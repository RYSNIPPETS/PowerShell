<#
.SYNOPSIS
    Installs a Windows product key on remote computers.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]]$ComputerName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9]{5}(?:-[A-Za-z0-9]{5}){4}$')]
    [string]$ProductKey,

    [pscredential]$Credential,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

foreach ($computer in $ComputerName) {
    $parameters = @{
        ComputerName = $computer
        ScriptBlock  = {
            param($Key)
            $result = & "$env:SystemRoot\System32\cscript.exe" //NoLogo "$env:SystemRoot\System32\slmgr.vbs" /ipk $Key
            if ($LASTEXITCODE -ne 0) {
                throw "slmgr.vbs failed with exit code $LASTEXITCODE."
            }
            $result
        }
        ArgumentList = $ProductKey
    }
    if ($Credential) {
        $parameters.Credential = $Credential
    }
    Invoke-Command @parameters
}
