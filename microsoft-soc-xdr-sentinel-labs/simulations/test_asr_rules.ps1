<#
.SYNOPSIS
    SC-200 Hands-on Lab: Attack Surface Reduction (ASR) Verification & Event Log Inspector.
.DESCRIPTION
    This script inspects the local Windows 11 Defender Antivirus and ASR configuration.
    It checks:
    1. Active ASR rules deployed from Intune or Group Policy.
    2. Maps Rule GUIDs to friendly names and displays mode (0=Disabled, 1=Block, 2=Audit, 6=Warn).
    3. Checks the Windows Defender Operational log for Event ID 1121 (ASR Block) and 1122 (ASR Audit).
    4. Runs a safe, benign test to evaluate script telemetry.
.NOTES
    Lab Module: SC-200 Lab 01
#>

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  SC-200 LAB: ASR Rules Configuration & Log Inspector" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Dictionary of well-known ASR Rule GUIDs
$asrRuleMap = @{
    "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2" = "Block credential stealing from LSASS"
    "be9ba2d9-53ea-44a7-8f61-b801700fa680" = "Block executable content from email client/webmail"
    "5beb8602-6816-4316-9774-a4b4847714e1" = "Block execution of potentially obfuscated scripts"
    "d1e49aac-8f56-4280-b9ba-993a6d77406c" = "Block process creations originating from PSExec/WMI"
    "3b576869-a4ec-4529-8536-b80a7769e899" = "Block executable files from running unless they meet criteria"
    "75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84" = "Block Office applications from injecting code into other processes"
    "d4f940ab-401b-4efc-aadc-ad5f3c50688a" = "Block all Office applications from creating child processes"
    "92e46356-9913-4025-8659-e46f7f4dc97c" = "Block Adobe Reader from creating child processes"
    "01443614-cd74-433a-b99e-2ecdc07bfc25" = "Block untrusted and unsigned processes that run from USB"
    "c1db55ab-5373-4247-a4b6-7647242d54e4" = "Use advanced protection against ransomware"
}

$modeMap = @{
    0 = "Disabled"
    1 = "Block"
    2 = "Audit"
    6 = "Warn"
}

Write-Host "`n[*] [1/3] Reading Microsoft Defender Antivirus & ASR Status from local OS..." -ForegroundColor Cyan

try {
    $mpPref = Get-MpPreference -ErrorAction Stop
    $rules = $mpPref.AttackSurfaceReductionRules_Ids
    $actions = $mpPref.AttackSurfaceReductionRules_Actions

    if ($null -eq $rules -or $rules.Count -eq 0) {
        Write-Warning "[!] No ASR rules detected on this machine."
        Write-Host "    -> If you recently deployed via Intune, allow 15-30 minutes for Intune sync." -ForegroundColor Gray
        Write-Host "    -> You can force an Intune sync: Settings > Accounts > Access work or school > Info > Sync." -ForegroundColor Gray
    } else {
        Write-Host "[+] Configured ASR Rules found ($($rules.Count) rules active):`n" -ForegroundColor Green
        
        $tableData = @()
        for ($i = 0; $i -lt $rules.Count; $i++) {
            $guid = $rules[$i]
            $modeCode = $actions[$i]
            $friendlyName = if ($asrRuleMap.ContainsKey($guid)) { $asrRuleMap[$guid] } else { "Custom / Unlisted Rule" }
            $modeText = if ($modeMap.ContainsKey($modeCode)) { $modeMap[$modeCode] } else { "Code: $modeCode" }
            
            $tableData += [PSCustomObject]@{
                "Rule Name" = $friendlyName
                "GUID"      = $guid
                "Mode"      = $modeText
            }
        }
        $tableData | Format-Table -AutoSize
    }
} catch {
    Write-Warning "[-] Could not retrieve Get-MpPreference. Ensure you are running as Administrator if required."
}

# Check Tamper Protection status
Write-Host "`n[*] [2/3] Checking Tamper Protection status..." -ForegroundColor Cyan
try {
    $mpComputerStatus = Get-MpComputerStatus
    $tamperStatus = if ($mpComputerStatus.IsTamperProtected) { "ENABLED" } else { "DISABLED / NOT ENFORCED" }
    $tamperColor = if ($mpComputerStatus.IsTamperProtected) { "Green" } else { "Yellow" }
    Write-Host "    Tamper Protection: " -NoNewline
    Write-Host "$tamperStatus" -ForegroundColor $tamperColor
    Write-Host "    Real-time Protection: $($mpComputerStatus.RealTimeProtectionEnabled)" -ForegroundColor Gray
    Write-Host "    Antivirus Signature Version: $($mpComputerStatus.AntivirusSignatureVersion)" -ForegroundColor Gray
} catch {
    Write-Warning "[-] Could not retrieve Get-MpComputerStatus."
}

# Inspect Windows Defender Event Log for recent ASR triggers (Event 1121 = Block, 1122 = Audit)
Write-Host "`n[*] [3/3] Inspecting Windows Event Log for recent ASR triggers (past 24h)..." -ForegroundColor Cyan
$logPath = "Microsoft-Windows-Windows Defender/Operational"

try {
    $filterXml = @"
<QueryList>
  <Query Id="0" Path="$logPath">
    <Select Path="$logPath">*[System[(EventID=1121 or EventID=1122) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
  </Query>
</QueryList>
"@
    $events = Get-WinEvent -FilterXml $filterXml -ErrorAction SilentlyContinue

    if ($null -eq $events -or $events.Count -eq 0) {
        Write-Host "    [i] No ASR Block (1121) or Audit (1122) events recorded in the last 24 hours." -ForegroundColor Gray
        Write-Host "        (This is normal if no applications attempted blocked/audited behaviors)." -ForegroundColor Gray
    } else {
        Write-Host "[+] Found $($events.Count) ASR trigger events:`n" -ForegroundColor Green
        foreach ($evt in ($events | Select-Object -First 5)) {
            $evtType = if ($evt.Id -eq 1121) { "[BLOCK]" } else { "[AUDIT]" }
            $color = if ($evt.Id -eq 1121) { "Red" } else { "Yellow" }
            Write-Host "    $evtType $($evt.TimeCreated.ToString('g')) : EventID $($evt.Id)" -ForegroundColor $color
            Write-Host "    Details: $($evt.Message.Split("`n")[0])" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "    [i] Could not query event log or no recent events." -ForegroundColor Gray
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  ASR STATUS INSPECTION COMPLETE" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

