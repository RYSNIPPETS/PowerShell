<#
.SYNOPSIS
    Installs, authorizes, and configures a Windows DHCP Server.
.EXAMPLE
    $scopes = @(
        @{ Name='CorpNet'; StartRange='10.0.0.20'; EndRange='10.0.0.254'; SubnetMask='255.255.255.0'; Router='10.0.0.1'; ExclusionStart='10.0.0.20'; ExclusionEnd='10.0.0.30' }
    )
    ./CreateDHCP.ps1 -ComputerName DHCP1 -DnsName DHCP1.contoso.com -IPAddress 10.0.0.3 -DnsDomain contoso.com -DnsServer 10.0.0.2 -Scope $scopes
#>

#Requires -RunAsAdministrator
#Requires -Modules DhcpServer, ServerManager

[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,

    [Parameter(Mandatory)]
    [string]$DnsName,

    [Parameter(Mandatory)]
    [ipaddress]$IPAddress,

    [Parameter(Mandatory)]
    [string]$DnsDomain,

    [Parameter(Mandatory)]
    [ipaddress[]]$DnsServer,

    [Parameter(Mandatory)]
    [hashtable[]]$Scope,

    [pscredential]$DnsUpdateCredential,

    [Parameter(DontShow)]
    [switch]$Confirm
)

$ConfirmPreference = 'None'
if ($Confirm) { Write-Verbose 'Confirmation is disabled for unattended execution.' }

function ConvertTo-IPv4Number {
    param([string]$Value)
    $address = [ipaddress]::Parse($Value)
    if ($address.AddressFamily -ne 'InterNetwork') { throw "Expected an IPv4 address, received '$Value'." }
    $bytes = $address.GetAddressBytes()
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($bytes) }
    [BitConverter]::ToUInt32($bytes, 0)
}

$scopeNames = @{}
$networks = [Collections.Generic.List[object]]::new()
$null = ConvertTo-IPv4Number $IPAddress
foreach ($address in $DnsServer) { $null = ConvertTo-IPv4Number $address }
foreach ($definition in $Scope) {
    foreach ($key in 'Name', 'StartRange', 'EndRange', 'SubnetMask', 'Router') {
        if ([string]::IsNullOrWhiteSpace($definition[$key])) { throw "Missing required scope field '$key'." }
    }
    $start = ConvertTo-IPv4Number $definition.StartRange
    $end = ConvertTo-IPv4Number $definition.EndRange
    $mask = ConvertTo-IPv4Number $definition.SubnetMask
    $router = ConvertTo-IPv4Number $definition.Router
    $network = $start -band $mask
    $hostBits = [uint32]::MaxValue - $mask
    $broadcast = $network + $hostBits
    if ($start -eq $network -or $end -eq $broadcast -or $router -in $network, $broadcast -or ($hostBits -band ([long]$hostBits + 1)) -ne 0 -or $mask -eq 0 -or
        $start -gt $end -or ($end -band $mask) -ne $network -or ($router -band $mask) -ne $network) {
        throw "Invalid range, router or mask for scope '$($definition.Name)'."
    }
    if ($scopeNames.ContainsKey($definition.Name)) { throw "Duplicate scope name '$($definition.Name)'." }
    foreach ($other in $networks) {
        if ($network -le $other.Last -and $broadcast -ge $other.First) {
            throw "Subnet for '$($definition.Name)' overlaps '$($other.Name)'."
        }
    }
    $scopeNames[$definition.Name] = $network
    $networks.Add([pscustomobject]@{ Name = $definition.Name; First = $network; Last = $broadcast })
    if ($definition.ExclusionStart -or $definition.ExclusionEnd) {
        $first = ConvertTo-IPv4Number $definition.ExclusionStart
        $last = ConvertTo-IPv4Number $definition.ExclusionEnd
        if ($first -lt $start -or $last -gt $end -or $first -gt $last) { throw "Invalid exclusions for scope '$($definition.Name)'." }
    }
}
$ErrorActionPreference = 'Stop'
$completed = [Collections.Generic.List[string]]::new()
try {
    $role = Install-WindowsFeature -Name DHCP -ComputerName $ComputerName -IncludeManagementTools
    if (-not $role.Success) { throw "DHCP role installation failed ($($role.ExitCode))." }
    $completed.Add('DHCP role installed or already present')

    $existingScopes = @(Get-DhcpServerv4Scope -ComputerName $ComputerName)
    foreach ($definition in $Scope) {
        foreach ($existing in $existingScopes) {
            $existingNetwork = ConvertTo-IPv4Number $existing.ScopeId
            $existingMask = ConvertTo-IPv4Number $existing.SubnetMask
            if ($existing.Name -eq $definition.Name) {
                if ($existingNetwork -ne $scopeNames[$definition.Name] -or
                    $existingMask -ne (ConvertTo-IPv4Number $definition.SubnetMask) -or
                    $existing.StartRange -ne [ipaddress]$definition.StartRange -or $existing.EndRange -ne [ipaddress]$definition.EndRange) {
                    throw "Existing scope '$($existing.Name)' differs from the requested address range or subnet."
                }
            }
            else {
                $requested = $networks | Where-Object Name -EQ $definition.Name
                if ($requested.First -le ($existingNetwork + ([uint32]::MaxValue - $existingMask)) -and $requested.Last -ge $existingNetwork) {
                    throw "Requested scope '$($definition.Name)' overlaps existing scope '$($existing.Name)'."
                }
            }
        }
    }

    $authorized = @(Get-DhcpServerInDC | Where-Object { $_.DnsName -eq $DnsName -or $_.IPAddress -eq $IPAddress })
    if ($authorized | Where-Object { $_.DnsName -ne $DnsName -or $_.IPAddress -ne $IPAddress }) {
        throw "A conflicting DHCP authorization already uses '$DnsName' or '$IPAddress'."
    }
    if (-not $authorized) {
        Add-DhcpServerInDC -DnsName $DnsName -IPAddress $IPAddress
        $completed.Add('Server authorized')
    }

    Set-DhcpServerv4DnsSetting -ComputerName $ComputerName -DynamicUpdates Always -DeleteDnsRRonLeaseExpiry $true
    $completed.Add('Dynamic DNS settings applied')
    if ($DnsUpdateCredential) {
        Set-DhcpServerDnsCredential -ComputerName $ComputerName -Credential $DnsUpdateCredential
        $completed.Add('DNS update credentials set')
    }

    foreach ($definition in $Scope) {
        $existing = $existingScopes | Where-Object Name -EQ $definition.Name
        if (-not $existing) {
            $existing = Add-DhcpServerv4Scope -ComputerName $ComputerName -Name $definition.Name -StartRange $definition.StartRange -EndRange $definition.EndRange -SubnetMask $definition.SubnetMask -State Active -PassThru
            $completed.Add("Created scope $($definition.Name)")
        }
        $scopeId = $existing.ScopeId
        if ($definition.ExclusionStart -and $definition.ExclusionEnd) {
            $match = Get-DhcpServerv4ExclusionRange -ComputerName $ComputerName -ScopeId $scopeId |
                Where-Object { $_.StartRange -eq [ipaddress]$definition.ExclusionStart -and $_.EndRange -eq [ipaddress]$definition.ExclusionEnd }
            if (-not $match) {
                Add-DhcpServerv4ExclusionRange -ComputerName $ComputerName -ScopeId $scopeId -StartRange $definition.ExclusionStart -EndRange $definition.ExclusionEnd
                $completed.Add("Created exclusion for $scopeId")
            }
        }

        Set-DhcpServerv4OptionValue -ComputerName $ComputerName -ScopeId $scopeId -Router $definition.Router -DnsDomain $DnsDomain -DnsServer $DnsServer
        $completed.Add("Applied options for $scopeId")
    }
    Get-DhcpServerv4Scope -ComputerName $ComputerName
}
catch {
    $progressDescription = if ($completed.Count) { $completed -join ', ' } else { 'none' }
    throw "DHCP configuration failed: $($_.Exception.Message) Completed stages: $progressDescription."
}
