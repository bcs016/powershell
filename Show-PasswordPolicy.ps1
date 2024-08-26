<#
.DESCRIPTION
    Get the password policy of a domain, and show with customized output

#>
$result = @()
$domains = @("contosoA.dom","contosoB.dom","contoseC.dom")

function beautify {
    param(
        [System.TimeSpan] $time_span
    )

    [string]$return = ""

    if( $time_span.Days    -gt 0){ 
            $return += $time_span.Days.ToString()    + " Day"
            if( $time_span.Days -gt 1){
                $return += "s "
            } else {
                $return += " "
            }
    }
    if( $time_span.Hours   -gt 0){ 
        $return += $time_span.Hours.ToString()   + " Hour"
        if( $time_span.Hours -gt 1){
            $return += "s "
        } else {
            $return += " "
        }
}
    if( $time_span.Minutes -gt 0){ 
        $return += $time_span.Minutes.ToString() + " Minute"
        if( $time_span.Minutes -gt 1){
            $return += "s "
        } else {
            $return += " "
        }
    }
    if( $time_span.TotalSeconds -eq 0) {
        $return += "None"
    }

    return $return
}

foreach( $domain in $domains) {


    $res = Get-ADDefaultDomainPasswordPolicy -Identity $domain

    $result += $res
}

$result | sort DistinguishedName| ft `
    @{N='Domain';E={$_.DistinguishedName.Replace("DC=","").Replace(",",".")}}, `
    @{N='Is Complex';E={$_.ComplexityEnabled}}, `
    @{N='Lock Duration';E={(beautify -time_span $_.LockoutDuration)}}, `
    @{N='Max Pass';E={(beautify -time_span $_.MaxPasswordAge)}}, `
    @{N='Min Pass';E={(beautify -time_span $_.MinPasswordAge)}}, `
    @{N='Min Pass Len';E={$_.MinPasswordLength}}, `
    @{N='Pass Hist Count';E={$_.PasswordHistoryCount}}