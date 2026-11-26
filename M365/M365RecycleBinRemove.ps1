<#
.SYNOPSIS
  Empty a SharePoint or OneDrive recycle bin, or permanently delete Entra ID recycled objects.
#>
[CmdletBinding()]
param(
    [string]$SharePointSiteUrl,
    [string]$TenantAdminUrl,
    [switch]$TenantLevel,
    [switch]$All,
    [switch]$PurgeDeletedUsers,
    [switch]$ForceDeviceCode,
    [string]$Tenant,
    [string]$CertificateThumbprint,
    [guid[]]$ItemId,
    [switch]$InteractiveSelection,
    [string]$PnPClientId,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$ErrorActionPreference = 'Stop'

function Get-PnPClientId {
    param(
        [string]$ExplicitClientId
    )

    foreach ($candidate in @(
            $ExplicitClientId,
            $env:ENTRAID_APP_ID,
            $env:ENTRAID_CLIENT_ID,
            $env:AZURE_CLIENT_ID
        )) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            return $candidate
        }
    }

    throw 'PnP.PowerShell requires a ClientId. Pass -PnPClientId or set ENTRAID_APP_ID/ENTRAID_CLIENT_ID.'
}

function Connect-PnPSite {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$ClientId,

        [string]$Tenant,
        [string]$Thumbprint,
        [switch]$DeviceLogin
    )

    $connectParams = @{
        Url              = $Url
        ClientId         = $ClientId
        ReturnConnection = $true
    }

    if ($DeviceLogin) { throw 'Use application certificate authentication for unattended operation.' }
    if (-not $Tenant -or -not $Thumbprint) { throw 'Supply -Tenant and -CertificateThumbprint.' }
    $connectParams.Tenant = $Tenant
    $connectParams.Thumbprint = $Thumbprint
    $connection = Connect-PnPOnline @connectParams -ErrorAction Stop
    $web = Get-PnPWeb -Connection $connection -Includes Url -ErrorAction Stop
    if (-not $web.Url -or ([uri]$web.Url).AbsoluteUri.TrimEnd('/') -ne ([uri]$Url).AbsoluteUri.TrimEnd('/')) {
        throw "The connection resolved to '$($web.Url)' instead of '$Url'."
    }
    $connection
}

function Select-RecycleBinItem {
    param(
        [Parameter(Mandatory)]
        [object[]]$Items
    )

    if (Get-Command -Name Out-GridView -ErrorAction SilentlyContinue) {
        $selectedRows = @(
            $Items | Select-Object Id, ItemType, LeafName, DirName, DeletedByName, DeletedDate |
                Out-GridView -PassThru -Title 'Select recycle bin items to clear'
        )
        return @($Items | Where-Object { $_.Id -in $selectedRows.Id })
    }

    $indexedItems = for ($index = 0; $index -lt $Items.Count; $index++) {
        [pscustomobject]@{
            Index       = $index
            ItemType    = $Items[$index].ItemType
            Name        = $Items[$index].LeafName
            Directory   = $Items[$index].DirName
            DeletedBy   = $Items[$index].DeletedByName
            DeletedDate = $Items[$index].DeletedDate
        }
    }

    $indexedItems | Select-Object -First 25 | Format-Table -AutoSize | Out-Host
    Write-Host 'Out-GridView is unavailable, so the first 25 items are shown above.'

    $selection = Read-Host 'Enter comma-separated indexes to clear, or press Enter to cancel'
    if ([string]::IsNullOrWhiteSpace($selection)) {
        return @()
    }

    $indexes = $selection -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^\d+$' } |
        ForEach-Object { [int]$_ } |
        Sort-Object -Unique

    return @(
        foreach ($index in $indexes) {
            if ($index -lt $Items.Count) {
                $Items[$index]
            }
        }
    )
}

if ($PurgeDeletedUsers) {
    if (-not (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue)) {
        throw 'Microsoft Graph PowerShell is required. Install it before using -PurgeDeletedUsers.'
    }

    if ($ForceDeviceCode) { throw 'Supply a preauthenticated Microsoft Graph context for -PurgeDeletedUsers.' }
    $context = Get-MgContext -ErrorAction Stop
    if (-not $context) { throw 'Supply a preauthenticated Microsoft Graph context for -PurgeDeletedUsers.' }
    if ($Tenant -and $context.TenantId -ne $Tenant) { throw 'The connected Graph tenant differs from -Tenant.' }
    $deletedItems = @(Get-MgDirectoryDeletedItemAsUser -All -ErrorAction Stop)
    $deletedUsers = @(
        $deletedItems | Where-Object {
            $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.user'
        }
    )

    if (-not $deletedUsers) {
        $deletedUsers = $deletedItems
    }

    if (-not $deletedUsers) {
        Write-Output 'No deleted users were found.'
        return
    }

    foreach ($user in $deletedUsers) {
        Remove-MgDirectoryDeletedItem -DirectoryObjectId $user.Id -Confirm:$false
    }

    Write-Output 'Deleted user recycle bin purged.'
    return
}

if (-not (Get-Command Connect-PnPOnline -ErrorAction SilentlyContinue)) {
    throw 'PnP.PowerShell is required for SharePoint and OneDrive recycle-bin operations.'
}
$resolvedClientId = Get-PnPClientId -ExplicitClientId $PnPClientId

if ($TenantLevel) {
    if (-not $TenantAdminUrl) {
        throw '-TenantAdminUrl is required when using -TenantLevel.'
    }

    $connection = Connect-PnPSite -Url $TenantAdminUrl -ClientId $resolvedClientId -DeviceLogin:$ForceDeviceCode -Tenant $Tenant -Thumbprint $CertificateThumbprint
    $items = @(Get-PnPTenantRecycleBinItem -Connection $connection)

    if (-not $items) {
        Write-Output 'Tenant recycle bin is empty.'
        return
    }

    foreach ($item in $items) {
        Clear-PnPTenantRecycleBinItem -Url $item.Url -Connection $connection -Wait -Force -ErrorAction Stop
    }
    if (Get-PnPTenantRecycleBinItem -Connection $connection -ErrorAction Stop) { throw 'Deleted sites remain in the tenant recycle bin.' }
    Write-Output 'Tenant recycle bin cleared.'

    return
}

if (-not $SharePointSiteUrl) {
    throw 'Provide -SharePointSiteUrl or use -TenantLevel.'
}

$siteConnection = Connect-PnPSite -Url $SharePointSiteUrl -ClientId $resolvedClientId -DeviceLogin:$ForceDeviceCode -Tenant $Tenant -Thumbprint $CertificateThumbprint

if ($All) {
    Clear-PnPRecycleBinItem -All -Force -Connection $siteConnection -ErrorAction Stop
    $remainingFirst = Get-PnPRecycleBinItem -FirstStage -RowLimit 1 -Connection $siteConnection -ErrorAction Stop
    $remainingSecond = Get-PnPRecycleBinItem -SecondStage -RowLimit 1 -Connection $siteConnection -ErrorAction Stop
    if ($remainingFirst -or $remainingSecond) { throw 'Items remain in the site recycle bin.' }
    Write-Output 'Site recycle bin cleared.'

    return
}

$recycleBinItems = @(Get-PnPRecycleBinItem -Connection $siteConnection)
if (-not $recycleBinItems) {
    Write-Output 'Site recycle bin is empty.'
    return
}

if ($ItemId) {
    $selectedItems = @($recycleBinItems | Where-Object { $_.Id -in $ItemId })
    if (@($ItemId | Sort-Object -Unique).Count -ne $selectedItems.Count) { throw 'One or more requested IDs were not found in the selected site.' }
}
elseif ($InteractiveSelection) { $selectedItems = @(Select-RecycleBinItem -Items $recycleBinItems) }
else { $recycleBinItems; return }
if (-not $selectedItems) {
    Write-Output 'No recycle bin items were selected.'
    return
}

foreach ($item in $selectedItems) {
    Clear-PnPRecycleBinItem -Identity $item.Id -Connection $siteConnection -Force -ErrorAction Stop
}
Write-Output 'Selected recycle bin items cleared.'
