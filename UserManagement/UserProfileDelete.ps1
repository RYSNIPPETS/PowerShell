#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Lists remote profiles, deletes one computer/SID pair, or opens an optional selection window.
#>

[CmdletBinding()]
param(
    [string]$ComputerName,
    [string]$SID,
    [switch]$Interactive,
    [string]$ComputersPath = (Join-Path -Path $PSScriptRoot -ChildPath 'Computers.txt'),
    [string]$LogPath = (Join-Path -Path $PSScriptRoot -ChildPath 'UserProfileDelete.log'),

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

$isWindowsPlatform = ($IsWindows -eq $true) -or ($env:OS -eq 'Windows_NT')
if (-not $isWindowsPlatform) {
    throw 'UserProfileDelete.ps1 is a Windows-only script.'
}

if ($SID -and -not $ComputerName) { throw 'Specify -ComputerName with -SID.' }
if ($Interactive) {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
}
$logDirectory = Split-Path -Path $LogPath -Parent
if ($logDirectory -and -not (Test-Path -LiteralPath $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
}

$script:Computers = if ($ComputerName) { $ComputerName } else {
    Get-Content -LiteralPath $ComputersPath -ErrorAction Stop |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique
}

if (-not $script:Computers) {
    throw ('No computer names were found in {0}' -f $ComputersPath)
}

$script:LogPath = $LogPath
$script:Form = $null
$script:ListBox = $null
$script:StatusLabel = $null

function Write-ProfileLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Add-Content -Path $script:LogPath -Value ('{0:s} {1}' -f (Get-Date), $Message)
}

function Get-RemoteProfile {
    $profileRows = [System.Collections.Generic.List[object]]::new()

    foreach ($computer in $script:Computers) {
        try {
            $profiles = Get-CimInstance -ComputerName $computer -ClassName Win32_UserProfile -ErrorAction Stop |
                Where-Object { $_.LocalPath -like 'C:\Users\*' -and -not $_.Special }

            foreach ($userProfile in $profiles) {
                $profileRows.Add([pscustomobject]@{
                        Computer = $computer
                        SID      = $userProfile.SID
                        Path     = $userProfile.LocalPath
                        Label    = "$computer  |  $($userProfile.LocalPath)  |  $($userProfile.SID)"
                    })
            }
        }
        catch {
            $message = 'Failed to query profiles on {0}: {1}' -f $computer, $_.Exception.Message
            Write-Warning $message
            Write-ProfileLog -Message $message
        }
    }

    $profileRows | Sort-Object Computer, SID -Unique
}

function Remove-SelectedProfile {
    [CmdletBinding()]
    param([object[]]$SelectedProfiles,

        [Parameter(DontShow)]
        [switch]$Confirm
    )
    $ConfirmPreference = 'None'
    if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

    if (-not $selectedProfiles) {
        [System.Windows.Forms.MessageBox]::Show('Select one or more profiles to delete first.')
        return
    }

    foreach ($row in $selectedProfiles) {
        try {
            $matchingProfile = Get-CimInstance -ComputerName $row.Computer -ClassName Win32_UserProfile -ErrorAction Stop |
                Where-Object { $_.SID -eq $row.SID -and $_.LocalPath -eq $row.Path -and -not $_.Special -and -not $_.Loaded }
            if (-not $matchingProfile) {
                Write-ProfileLog "Skipped $($row.Label): profile changed, loaded or absent."
                continue
            }

            $matchingProfile | Remove-CimInstance -Confirm:$false -ErrorAction Stop
            Write-ProfileLog "Deleted $($row.Label)"
        }
        catch {
            $message = "Failed to delete $($row.Label): $($_.Exception.Message)"
            Write-Warning $message
            Write-ProfileLog $message
        }
    }

    if (-not $Interactive) { return }
    $script:StatusLabel.Text = 'Deletion complete. Review the log for details.'
    [System.Windows.Forms.MessageBox]::Show(('Deletion complete. Review the log at {0}' -f $script:LogPath))
}

function Show-ProfileDeletionForm {
    $profileRows = @(Get-RemoteProfile)

    $script:Form = New-Object System.Windows.Forms.Form
    $script:Form.Text = 'Delete Remote User Profiles'
    $script:Form.Size = New-Object System.Drawing.Size(420, 380)
    $script:Form.StartPosition = 'CenterScreen'
    $script:Form.TopMost = $true

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(10, 10)
    $titleLabel.Size = New-Object System.Drawing.Size(390, 20)
    $titleLabel.Text = 'Select the computer and profile to delete.'
    $script:Form.Controls.Add($titleLabel)

    $script:ListBox = New-Object System.Windows.Forms.ListBox
    $script:ListBox.Location = New-Object System.Drawing.Point(10, 35)
    $script:ListBox.Size = New-Object System.Drawing.Size(390, 220)
    $script:ListBox.SelectionMode = 'MultiExtended'
    $script:ListBox.DisplayMember = 'Label'
    $script:ListBox.HorizontalScrollbar = $true
    foreach ($row in $profileRows) {
        [void]$script:ListBox.Items.Add($row)
    }
    $script:Form.Controls.Add($script:ListBox)

    $deleteButton = New-Object System.Windows.Forms.Button
    $deleteButton.Location = New-Object System.Drawing.Point(100, 295)
    $deleteButton.Size = New-Object System.Drawing.Size(95, 28)
    $deleteButton.Text = 'Delete Profile'
    $deleteButton.Add_Click({ Remove-SelectedProfile -SelectedProfiles @($script:ListBox.SelectedItems) })
    $script:Form.Controls.Add($deleteButton)

    $logButton = New-Object System.Windows.Forms.Button
    $logButton.Location = New-Object System.Drawing.Point(205, 295)
    $logButton.Size = New-Object System.Drawing.Size(95, 28)
    $logButton.Text = 'View Log'
    $logButton.Add_Click({
            if (Test-Path -LiteralPath $script:LogPath) {
                Invoke-Item -Path $script:LogPath
            }
        })
    $script:Form.Controls.Add($logButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(310, 295)
    $cancelButton.Size = New-Object System.Drawing.Size(90, 28)
    $cancelButton.Text = 'Close'
    $cancelButton.Add_Click({ $script:Form.Close() })
    $script:Form.Controls.Add($cancelButton)

    $script:StatusLabel = New-Object System.Windows.Forms.Label
    $script:StatusLabel.Location = New-Object System.Drawing.Point(10, 265)
    $script:StatusLabel.Size = New-Object System.Drawing.Size(390, 20)
    $script:StatusLabel.Text = 'Ready.'
    $script:Form.Controls.Add($script:StatusLabel)

    [void]$script:Form.ShowDialog()
}

if ($Interactive) { Show-ProfileDeletionForm }
elseif ($SID) {
    $row = Get-RemoteProfile | Where-Object SID -EQ $SID
    if (-not $row) { throw "Profile '$SID' was not found on '$ComputerName'." }
    Remove-SelectedProfile -SelectedProfiles @($row)
}
else { Get-RemoteProfile }
