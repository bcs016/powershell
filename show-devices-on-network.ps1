<#
.SYNOPSIS
    Een light-wight netwerk scanner in PowerShell die apparaten in het lokale subnet detecteert, 
    hun hostnamen en MAC-adressen ophaalt, en controleert op open poorten.
    Equivalent van nmap met de optie -Pn

.NOTES
    - Gebruikt Test-Connection voor ping tests.
    - Maakt gebruik van ARP voor MAC-adres resolutie.
    - Voert een eenvoudige TCP connect scan uit op opgegeven poorten.
    - Beperkt zich tot het lokale /24 subnet van de primaire netwerkadapter.

.SYNTAX
    .\show-devices-on-network.ps1 [-Mode <Ping|PortScan>]

    Default modus is "Ping" waarbij alleen apparaten worden gedetecteerd.



.NOTES
    Datum : 2026-04-29

#>

param (
    [ValidateSet("Ping", "PortScan")]
    [string]$Mode = "Ping"
)

# -------------------------------
# Variabelen, pas aan waar nodig
# -------------------------------
$PortsToScan = @(22, 80, 443, 3389)
$TcpTimeoutMs = 200
$ThrottleLimit = 50

# -------------------------------
# Discover local /24 subnet
# -------------------------------
$interfaces = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
        $_.InterfaceAlias -notmatch 'Loopback' -and
        $_.IPAddress -notmatch '^169\.254'
    } |
    Select-Object InterfaceIndex, InterfaceAlias, IPAddress | Sort-Object InterfaceIndex


if( -not $interfaces){
    Write-Error "No suitable network interfaces found."
    return
}

Write-Host "Available network interfaces:" -ForegroundColor Cyan
$interfaces | ft -AutoSize

$idx = REad-Host "`nEnter the InterfaceIndex to scan"
$selected = $interfaces | where-object {$_.InterfaceIndex -eq [int]$idx}

if(-not $selected){
    Write-Error "Invalid InterfaceIndex selected."
    return
}


$ipParts = $selected.IPAddress.Split('.')
$Subnet = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2])"

Write-Host "`nMode       : $Mode"
Write-Host "Interface  : $($selected.InterfaceAlias) (Index: $($selected.InterfaceIndex))"
Write-Host "Subnet     : $Subnet.0/24"
Write-Host "Scanning..."

# -------------------------------
# Scan het netwerk
# -------------------------------
$results = 1..254 | ForEach-Object -Parallel {
    #param ($Subnet, $Mode, $PortsToScan, $TcpTimeoutMs)

    $ip = "$using:Subnet.$_"
    #Write-Host "Checking $ip..." -ForegroundColor Gray
    Write-Host "." -NoNewline
    $pingalive = $false
    $openPorts = @()

    # ICMP, ping only
    $pingAlive = Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds 1

    if ($using:Mode -eq "Ping" -and -not $pingAlive) {
        return $null
    }

    # portscan (loopt zelfs als ping niet mogelijk is)
    if ($using:mode -eq "PortScan") {
        foreach ($port in $using:PortsToScan) {
            try {
                $client = New-Object System.Net.Sockets.TcpClient
                $iar = $client.BeginConnect($ip, $port, $null, $null)

                if ($iar.AsyncWaitHandle.WaitOne($using:TcpTimeoutMs, $false)) {
                    $client.EndConnect($iar)
                    $openPorts += $port
                }
                $client.Close()
            } catch {}
        }
    }

    # Hostname resolutie
    try {
        $hostname = ([System.Net.Dns]::GetHostEntry("$ip")).HostName
    } catch {
        $hostname = $null
    }

    # MAC via ARP (best effort)
    $mac = $null
    arp -a $ip | ForEach-Object {
        if ($_ -match "([0-9a-f]{2}(-[0-9a-f]{2}){5})") {
            $mac = $matches[1]
        }
    }

    [PSCustomObject]@{
        IPAddress    = $ip
        Pinable      = $pingAlive
        Hostname     = $hostname
        MACAddress   = $mac
        OpenPorts    = if ($Mode -eq "PortScan") { $openPorts -join ", " } else { $null }
    }

} -ThrottleLimit $ThrottleLimit 
Write-Host ""

# -------------------------------
# Output
# -------------------------------
$results |
    Where-Object { $_ } |
    Sort-Object IPAddress |
    Format-Table -AutoSize