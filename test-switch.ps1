$string1 = "Windows Server Standard 2012 Datacenter"
$string1 = "Windows Server Standard 2016 Datacenter"
$string1 = "Windows Server Standard 2019 Datacenter"
#$string1 = "Windows Server Standard 2022 Datacenter"

$result = switch -Wildcard ( $string1 ) {
    "*2012*" {"2012"; Break}
    "*2016*" {"2016"; Break}
    "*2019*" {"2019"; Break}
    "*2022*" {"2022"; Break}
    Default {"ERROR"}
}

if ($result -eq "ERROR"){
    Write-Host "Invalid result"
} else {
    Write-Host "Result = $result"
}

