# dnsinfo.ps1
# parameters:  1 - dnsname
#           :  2 = server to use as lookup server

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string] $dnsName = $null,
    
    [Parameter(Mandatory=$false)]
    [string] $lookupServer = $null
)

#==============================================================================

#==============================================================================

Write-Host "`nFind info about : $dnsName"
if( $lookupServer ){
    Write-Host "     dns server : $lookupserver" -NoNewline
} 
Write-Host "`n"

$soaName = Resolve-Dns $dnsName SOA | select-object -Expand Answers
$soaIp   = (Resolve-Dns $soaName.MName A | select-object -Expand Answers).Address.IPAddressToString

$aRec    = Resolve-Dns $dnsName A    -NameServer $soaIp | select-object -Expand Answers
$aaRec   = Resolve-Dns $dnsName AAAA -NameServer $soaIp | select-object -Expand Answers
$nsRec   = Resolve-Dns $dnsName NS   -NameServer $soaIp | select-object -Expand Answers
$mxRec   = Resolve-Dns $dnsName MX   -NameServer $soaIp | select-object -Expand Answers
$txtRec  = Resolve-Dns $dnsName TXT  -NameServer $soaIp | select-object -Expand Answers

"SOA       {0}" -f $soaName.MName.Value
"A         {0}" -f $aRec.Address.IPAddressToString
"AAAA      {0}" -f $aaRec.Address.IPAddressToString
foreach( $ns in $nsRec){
    "NS        {0}" -f $ns.NSDName
}
"MX        {0} {1}" -f $mxRec.Preference, $mxRec.Exchange
"TXT       {0}" -f $txtRec.EscapedText

"`n" 

#exit
#$aRecords = @("A","AAAA","NS","MX","TXT")
#foreach( $rec in $aRecords ){
#    Resolve-Dns $dnsName $rec -NameServer $soaIp | select-object -Expand Answers
#}
