<#
.SYNOPSIS
    SC-200 Hands-on Lab: Safe Living-off-the-Land (LOLBAS) & Suspicious Process Simulation.
.DESCRIPTION
    This script is 100% benign, non-destructive, and designed specifically for testing
    Microsoft Defender for Endpoint (MDE) detection telemetry and incident response.
    
    It simulates two common attacker techniques:
    1. MITRE T1105 (Ingress Tool Transfer): Uses certutil.exe with -urlcache and -split
       to download a benign text file from official Microsoft Learn / GitHub documentation.
    2. MITRE T1059.001 (Command and Scripting Interpreter: PowerShell): Executes a safe,
       base64-encoded command string that prints a benign status message to stdout.

    After generating the telemetry, the script pauses and automatically removes temporary files.
.NOTES
    Lab Module: SC-200 Lab 02 & Lab 06
    Author: SC-200 Practical Lab Series
#>

[CmdletBinding()]
param(
    [string]$TargetDir = "$env:TEMP\SC200_Lab",
    [int]$PauseSeconds = 5
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  SC-200 LAB: Safe Process Simulation & EDR Telemetry Test" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "[!] Note: This test is completely harmless and performs no malicious actions.`n" -ForegroundColor Yellow

# Step 1: Ensure temporary sandbox directory exists
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Write-Host "[+] Created temporary working directory: $TargetDir" -ForegroundColor Green
}

# Step 2: Simulate LOLBAS Ingress Tool Transfer (certutil.exe download)
Write-Host "`n[*] [Phase 1/2] Simulating LOLBAS activity using certutil.exe..." -ForegroundColor Cyan
$sampleUrl = "https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/README.md"
$outputFile = Join-Path $TargetDir "sentinel_readme_sample.txt"

$certutilCmd = "certutil.exe -urlcache -split -f `"$sampleUrl`" `"$outputFile`""
Write-Host "    Executing command: $certutilCmd" -ForegroundColor Gray

try {
    Start-Process -FilePath "certutil.exe" -ArgumentList "-urlcache", "-split", "-f", "`"$sampleUrl`"", "`"$outputFile`"" -Wait -NoNewWindow
    Write-Host "[+] Phase 1 Complete: certutil executed successfully." -ForegroundColor Green
    Write-Host "    Telemetry generated for: DeviceProcessEvents & DeviceNetworkEvents" -ForegroundColor DarkGray
} catch {
    Write-Warning "[-] Error running certutil: $_"
}

# Step 3: Simulate Encoded PowerShell Execution (T1059.001)
Write-Host "`n[*] [Phase 2/2] Simulating Obfuscated / Encoded PowerShell execution..." -ForegroundColor Cyan
$rawCommand = "Write-Host '*** SC-200 Telemetry Verification: Benign Script Executed ***' -ForegroundColor Green"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($rawCommand)
$encodedCommand = [Convert]::ToBase64String($bytes)

Write-Host "    Executing: powershell.exe -NoProfile -NonInteractive -EncodedCommand $encodedCommand" -ForegroundColor Gray

try {
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile", "-NonInteractive", "-EncodedCommand", $encodedCommand -Wait -NoNewWindow
    Write-Host "[+] Phase 2 Complete: Encoded PowerShell executed." -ForegroundColor Green
    Write-Host "    Telemetry generated for: DeviceProcessEvents (ProcessCommandLine with -EncodedCommand)" -ForegroundColor DarkGray
} catch {
    Write-Warning "[-] Error running encoded PowerShell: $_"
}

# Step 4: Cleanup
Write-Host "`n[*] Waiting $PauseSeconds seconds before automatic cleanup..." -ForegroundColor Yellow
Start-Sleep -Seconds $PauseSeconds

if (Test-Path $outputFile) {
    Remove-Item -Path $outputFile -Force -ErrorAction SilentlyContinue
    Write-Host "[+] Cleaned up temporary downloaded file: $outputFile" -ForegroundColor Green
}

# Flush certutil cache to keep system clean
Start-Process -FilePath "certutil.exe" -ArgumentList "-urlcache", "split", "-delete" -Wait -NoNewWindow -ErrorAction SilentlyContinue | Out-Null
Write-Host "[+] Flushed local certutil urlcache." -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  TEST COMPLETED SUCCESSFULLY" -ForegroundColor Green
Write-Host "  Next Step: Navigate to security.microsoft.com" -ForegroundColor White
Write-Host "  1. Check 'Incidents & alerts' or 'Advanced Hunting'." -ForegroundColor White
Write-Host "  2. Run the queries provided in 'queries/hunting_queries.kql'." -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan

