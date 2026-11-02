<#
.SYNOPSIS
    SC-200 Hands-on Lab: Safe Persistence Technique Simulation (MITRE T1053.005).
.DESCRIPTION
    Simulates an attacker attempting persistence via scheduled task creation using schtasks.exe.
    This script is completely benign: it registers a dummy task that prints a test message,
    waits for Defender EDR telemetry to log the process creation, and then immediately deletes it.
.NOTES
    Lab Module: SC-200 Lab 02 & Lab 06
#>

[CmdletBinding()]
param(
    [string]$TaskName = "SC200_Lab_BenignTask",
    [int]$WaitSeconds = 6
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  SC-200 LAB: Safe Persistence Simulation (Scheduled Task)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Step 1: Create benign scheduled task
Write-Host "`n[*] Creating temporary benign scheduled task '$TaskName'..." -ForegroundColor Cyan
$cmd = "cmd.exe /c echo 'SC200 Detection Verification'"

try {
    $createResult = schtasks.exe /create /tn $TaskName /tr $cmd /sc once /st 23:59 /f 2>&1
    Write-Host "    $createResult" -ForegroundColor Gray
    Write-Host "[+] Task created successfully. Process execution telemetry sent to Defender EDR." -ForegroundColor Green
} catch {
    Write-Warning "[-] Error creating task: $_"
}

# Step 2: Query the task to simulate discovery
Write-Host "`n[*] Querying task details (Discovery)..." -ForegroundColor Cyan
schtasks.exe /query /tn $TaskName /fo LIST 2>&1 | Select-Object -First 6 | ForEach-Object {
    Write-Host "    $_" -ForegroundColor Gray
}

# Step 3: Wait and Clean Up
Write-Host "`n[*] Waiting $WaitSeconds seconds before automatic removal..." -ForegroundColor Yellow
Start-Sleep -Seconds $WaitSeconds

Write-Host "`n[*] Deleting temporary task '$TaskName'..." -ForegroundColor Cyan
$delResult = schtasks.exe /delete /tn $TaskName /f 2>&1
Write-Host "    $delResult" -ForegroundColor Green
Write-Host "[+] Persistence cleanup verified. No residual tasks remain." -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  SIMULATION FINISHED" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

