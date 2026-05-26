<#
.DESCRIPTION
    Show DNS info on a given domain name

.PARAMETER domain
    De domain name to query. Mandatory

.PARAMETER dnsServer
    De DNS server to use. Optional

.NOTES
    Author mike.beijerbacht@gmail.com

#>
param(
    [Parameter(Mandatory=$true)]
    [string] $domain=$null,

    [Parameter(Mandatory=$false)]
    [string] $dnsServer=$null
)
$results = @()
$foundDnsServer = $null

write-verbose "[+] Getting SOA record"
$SOA=$null

if( ![string]::IsNullOrEmpty($dnsServer) ){
    $record = Resolve-DnsName -Name $domain -Type SOA -Server $dnsServer  -ErrorAction SilentlyContinue
    if($record.PrimaryServer){
        $SOA = $record.PrimaryServer
        $TTL = $record.DefaultTTL
        $foundDnsServer=$dnsServer
    }
} else {
    $record = Resolve-DnsName -Name $domain -Type SOA  -ErrorAction SilentlyContinue
    if($record.PrimaryServer){
        $SOA = $record.PrimaryServer
        $TTL = $record.DefaultTTL
        $foundDnsServer=(Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses[0]
    }
}

if( $null -ne $SOA){
    $results += [PSCustomObject]@{ 
        Type  = "SOA"
        TTL   = $TTL 
        Value = "$SOA (dns server used: $foundDnsServer)"
    }
}
#$results | ft

write-verbose "[+] Getting A records"
#$aRecords = Resolve-DnsName -Name $domain -Type A -Server $SOA -TcpOnly
$aRecords = Resolve-DnsName -Name $domain -Type A  -ErrorAction SilentlyContinue
foreach( $rec in $aRecords){
    if($rec.IPAddress){
        $results += [PSCustomObject]@{
            Type  = "A" 
            TTL   = $rec.TTL
            Value = $rec.IPAddress
        }
    }
}

write-verbose "[+] Getting AAAA records"
#$aaaaRecords = Resolve-DnsName -Name $domain -Type AAAA -Server $SOA -TcpOnly
$aaaaRecords = Resolve-DnsName -Name $domain -Type AAAA  -ErrorAction SilentlyContinue
foreach( $rec in $aaaaRecords){
    if( $rec.Type -eq "AAAA" -and $rec.IPAddress){
        $results += [PSCustomObject]@{
            Type  = "AAAA"
            TTL   = $rec.TTL
            Value = $rec.IPAddress
        }
    }
}
write-verbose "[+] Getting NS records"
#$nsRecords = Resolve-DnsName -Name $domain -Type NS -Server $SOA -TcpOnly
$nsRecords = Resolve-DnsName -Name $domain -Type NS  -ErrorAction SilentlyContinue
foreach( $rec in $nsRecords){
    if($rec.NameHost){
        $results += [PSCustomObject]@{
            Type  = "NS" 
            TTL   = $rec.TTL
            Value = $rec.NameHost
        }
    }
}
write-verbose "[+] Getting MX records"
#$mxRecords = Resolve-DnsName -Name $domain -Type MX -Server $SOA -TcpOnly
$mxRecords = Resolve-DnsName -Name $domain -Type MX  -ErrorAction SilentlyContinue
foreach( $rec in $mxRecords){
    if( $rec.NameExchange){
        $results += [PSCustomObject]@{
            Type  = "MX" 
            TTL   = $rec.TTL
            Value = "$($rec.Preference) " + $rec.NameExchange
        }
    }
}
write-verbose "[+] Getting CNAME records"
$cRecords = Resolve-DnsName -Name $domain -Type CNAME  -ErrorAction SilentlyContinue
foreach( $rec in $cRecords){
    if( $rec.NameHost){
        $results += [PSCustomObject]@{
            Type  = "CNAME" 
            TTL   = $rec.TTL
            Value = $rec.NameHost
        }
    }
}
write-verbose "[+] Getting TXT records"
#$txtRecords = Resolve-DnsName -Name $domain -Type TXT -Server $SOA -TcpOnly | Where-Object {$_.QueryType -eq "TXT"}| select-object Name, Type, @{N="Strings";E={$_.Strings -join ""}} 
$txtRecords = Resolve-DnsName -Name $domain -Type TXT  -ErrorAction SilentlyContinue | Where-Object {$_.QueryType -eq "TXT"}| select-object Name, Type, @{N="Strings";E={$_.Strings -join ""}} 
foreach( $rec in $txtRecords){
    if( $rec.Strings){
        $results += [PSCustomObject]@{
            Type  = "TXT" 
            TTL   = $rec.TTL
            Value = $rec.Strings
        }
    }
}

$results | ft -AutoSize -Wrap

exit

$results=@()

foreach($rec in $records) {

    $t = $rec.GetType()

    $obj = [PSCustomObject]@{
        Name = $rec.Name
        Type = ""
        TTL  = $rec.TTL
        Section = $rec.Section
        Value = ""
    }
    switch($t){
        "Microsoft.DnsClient.Commands.DnsRecord_A"   { $obj.Type = "A"  ; $obj.Value = $rec.IPAddress}
        "Microsoft.DnsClient.Commands.DnsRecord_PTR" { $obj.Type = "NS" ; $obj.Value = $rec.NameHost}
        "Microsoft.DnsClient.Commands.DnsRecord_SOA" { $obj.Type = "SOA"; $obj.Value = $rec.PrimaryServer}
        "Microsoft.DnsClient.Commands.DnsRecord_MX"  { $obj.Type = "MX" ; $obj.Value = $rec.NameExchange}
        "Microsoft.DnsClient.Commands.DnsRecord_TXT" { $obj.Type = "TXT"; $obj.Value = $rec.Strings}
        Default { $obj.Type = "Unknown"; $obj.Value = "Unknown"}
    }

    $results += $obj
}

$results | ft -AutoSize -Wrap
