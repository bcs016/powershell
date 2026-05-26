<#
.SYNOPSIS
    This script creates a memory dump of the MFT (Master File Table) from a Windows system.
.DESCRIPTION
    The script creates a Volume Shadow Copy of the system drive and then copies the MFT to a specified output location.
.PARAMETER OutputDir
    The directory where the MFT dump will be saved.
.PARAMETER OutputFile
    The name of the output file for the MFT dump.
#>

# ==============================
# CONFIG
# ==============================
$OutputDir   = "C:\temp\forensics"
$LogFile     = Join-Path $OutputDir "transcript.txt"
$MFTECmdPath = "C:\ZimmermanTools\net9\MFTECmd.exe"

$CsvDir      = Join-Path $OutputDir "csv"
$JsonDir     = Join-Path $OutputDir "json"

# ==============================
# ADMIN CHECK
# ==============================
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "[!] Elevating..."
    Start-Process pwsh `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

# ==============================
# PREP
# ==============================
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
New-Item -ItemType Directory -Path $CsvDir -Force | Out-Null
New-Item -ItemType Directory -Path $JsonDir -Force | Out-Null

Start-Transcript -Path $LogFile -Force

Write-Host "[*] Starting at $(Get-Date)"

# ==============================
# VALIDATE MFTECmd
# ==============================
if (-not (Test-Path $MFTECmdPath)) {
    Write-Error "MFTECmd not found at $MFTECmdPath"
    Stop-Transcript
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host "[*] Using MFTECmd at $MFTECmdPath"

# ==============================
# RUN MFTECmd
# ==============================
Write-Host "[*] Parsing MFT from C: ..."

try {
    & $MFTECmdPath `
        -f C:\`$MFT `
        --csv $CsvDir `
        --csvf MFT_parsed.csv #`
        #--json $JsonDir
}
catch {
    Write-Error "MFTECmd execution failed: $_"
    Stop-Transcript
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host "[+] MFTE parsing complete"


# ==============================
# HASH OUTPUT FILES
# ==============================
Write-Host "[*] Hashing output files..."
Stop-Transcript | Out-Null
Get-ChildItem $OutputDir -Recurse -File | ForEach-Object {
    $hash = Get-FileHash $_.FullName -Algorithm SHA256
    "$($_.FullName),$($hash.Hash)" >> (Join-Path $OutputDir "hashes.txt")
}

Write-Host "[+] Hash list saved to hashes.txt"

# ==============================
# DONE
# ==============================
Write-Host "[*] Completed at $(Get-Date)"

#Stop-Transcript

Read-Host "Press Enter to exit..."
