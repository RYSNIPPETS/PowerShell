#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users.Actions

<#
.SYNOPSIS
    Sends email through Microsoft Graph using delegated or application authentication.
#>

[CmdletBinding(DefaultParameterSetName = 'ExistingContext')]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(Mandatory, ParameterSetName = 'ClientSecret')]
    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [string]$ClientId,

    [Parameter(Mandatory, ParameterSetName = 'ClientSecret')]
    [securestring]$ClientSecret,

    [Parameter(Mandatory, ParameterSetName = 'Certificate')]
    [string]$CertificateThumbprint,

    [Parameter(Mandatory)]
    [string]$SenderUserPrincipalName,

    [Parameter(Mandatory)]
    [mailaddress[]]$To,

    [mailaddress[]]$Cc,

    [Parameter(Mandatory)]
    [string]$Subject,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Body,

    [ValidateSet('Text', 'HTML')]
    [string]$BodyType = 'HTML',

    [string[]]$AttachmentPath,

    [bool]$SaveToSentItems = $true,

    [switch]$UseDeviceCode,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$connectParameters = @{ TenantId = $TenantId; NoWelcome = $true }
switch ($PSCmdlet.ParameterSetName) {
    'ClientSecret' {
        $connectParameters.ClientSecretCredential = [pscredential]::new($ClientId, $ClientSecret)
    }
    'Certificate' {
        $connectParameters.ClientId = $ClientId
        $connectParameters.CertificateThumbprint = $CertificateThumbprint
    }
    default {
        if ($UseDeviceCode) { throw 'Use application authentication or an existing Graph context.' }
        $context = Get-MgContext -ErrorAction Stop
        if (-not $context -or $context.TenantId -ne $TenantId) { throw 'Connect to the requested tenant or supply application credentials.' }
    }
}

$toRecipients = @($To | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address } } })
$ccRecipients = @($Cc | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address } } })
$attachments = @($AttachmentPath | ForEach-Object {
        $file = Get-Item -LiteralPath $_ -ErrorAction Stop
        $contentType = switch ($file.Extension.ToLowerInvariant()) {
            '.csv' { 'text/csv' }
            '.html' { 'text/html' }
            '.jpg' { 'image/jpeg' }
            '.jpeg' { 'image/jpeg' }
            '.png' { 'image/png' }
            '.pdf' { 'application/pdf' }
            '.txt' { 'text/plain' }
            '.xlsx' { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
            '.zip' { 'application/zip' }
            default { 'application/octet-stream' }
        }
        @{
            '@odata.type' = '#microsoft.graph.fileAttachment'
            Name          = $file.Name
            ContentType   = $contentType
            ContentBytes  = [Convert]::ToBase64String([IO.File]::ReadAllBytes($file.FullName))
        }
    })

if ($PSCmdlet.ParameterSetName -ne 'ExistingContext') { Connect-MgGraph @connectParameters -ErrorAction Stop | Out-Null }
try {
    $message = @{
        Subject      = $Subject
        Body         = @{ ContentType = $BodyType; Content = $Body }
        ToRecipients = $toRecipients
    }
    if ($ccRecipients.Count -gt 0) { $message.CcRecipients = $ccRecipients }
    if ($attachments.Count -gt 0) { $message.Attachments = $attachments }

    Send-MgUserMail -UserId $SenderUserPrincipalName -Message $message -SaveToSentItems:$SaveToSentItems
}
finally {
    if ($PSCmdlet.ParameterSetName -ne 'ExistingContext') { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null }
}
