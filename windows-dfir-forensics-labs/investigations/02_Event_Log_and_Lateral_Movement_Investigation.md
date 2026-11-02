# Investigation Playbook 02: Windows Event Log Correlation & Lateral Movement Triage

| Metadata | Details |
| :--- | :--- |
| **DFIR Domain** | Authentication Forensics, Lateral Movement & Persistence |
| **Artifacts Covered** | `Security.evtx`, `System.evtx`, `Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx`, `Microsoft-Windows-PowerShell%4Operational.evtx` |
| **Forensic Tooling** | `EvtxECmd.exe`, `Timeline Explorer`, PowerShell `Get-WinEvent` |

---

## 🎯 1. Investigative Objective

During an intrusion, adversaries pivot across the network using stolen credentials via SMB (`PsExec`), WMI, WinRM, or Remote Desktop Protocol (RDP), install malicious Windows services, and attempt to cover their tracks by clearing event logs. This playbook details how to reconstruct the complete lateral movement chain across Windows Event Logs (`C:\Windows\System32\winevt\Logs\`).

---

## 🔬 2. High-Signal Event IDs & Logon Type Reference

### A. `Security.evtx` — Logon Types & Authentication Tracking
When investigating **Event ID 4624** (Successful Logon) and **Event ID 4625** (Failed Logon), the **Logon Type** field determines how the adversary accessed the host:

| Logon Type | Access Vector | Typical Adversary / Operational Context |
| :---: | :--- | :--- |
| **Type 2** | Interactive | Local console logon (physical keyboard/KVM or VM console). |
| **Type 3** | Network | SMB file share access (`\\server\C$`), RPC, PsExec network stage, WinRM. |
| **Type 4** | Batch | Scheduled Task execution running under specified user credentials. |
| **Type 5** | Service | Windows Service startup (`services.exe`). |
| **Type 7** | Unlock | Workstation screen unlock (also seen on RDP reconnect to locked session). |
| **Type 9** | NewCredentials | `runas /netonly` or Mimikatz `sekurlsa::pth` (Pass-the-Hash — uses local identity locally, alternate credentials on the network). |
| **Type 10** | RemoteInteractive | Standard Remote Desktop Protocol (RDP) / Terminal Services logon. |

---

### B. Reconstructing an RDP Lateral Movement Session (End-to-End Lifecycle)
An authentic RDP session leaves correlated traces across multiple log channels:
1. **`Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational.evtx`:**
   - **Event ID 1149:** Network-level pre-authentication attempt (logs username, domain, and source IP; note that 1149 can fire on port scan/connection setup before full authentication completes).
2. **`Security.evtx`:**
   - **Event ID 4624 (`LogonType 10` or `LogonType 7`):** Authenticated session established.
   - **Event ID 4672:** Special privileges (`SeDebugPrivilege`, `SeBackupPrivilege`) assigned to the new administrative logon.
3. **`Microsoft-Windows-TerminalServices-LocalSessionManager/Operational.evtx`:**
   - **Event ID 21:** Session logon succeeded (allocates `Session ID` + records Source IP).
   - **Event ID 22:** Shell start notification (`explorer.exe` initialized).
   - **Event ID 24:** Session **Disconnected** (user closed the RDP window `[X]` without logging off; processes continue running in background).
   - **Event ID 25:** Session **Reconnected** (records new Source IP).
4. **`Security.evtx`:**
   - **Event ID 4634 / 4647:** Formal session logoff.

---

### C. Detecting Service Installation, Process Creation & Anti-Forensics
- **`System.evtx` — Event ID 7045** (`Security.evtx` **4697**): A new service was installed in the system (captures Service Name, Image Path/Command Line, Service Type, and Account Name—primary indicator for `PsExec` / `PSEXESVC.exe`, Cobalt Strike `svc`, and ransomware persistence).
- **`Security.evtx` — Event ID 4688:** Process creation with full `CommandLine` auditing and Creator Process ID.
- **`Microsoft-Windows-PowerShell/Operational.evtx` — Event ID 4104:** PowerShell **Script Block Logging**—captures the de-obfuscated PowerShell script block content executed in memory.
- **`Security.evtx` — Event ID 1102** (`System.evtx` **104**): The audit log was cleared (`wevtutil cl Security`).

```powershell
# Parse all .evtx files in a triage image into a unified CSV timeline using EvtxECmd.exe
EvtxECmd.exe -d "C:\Windows\System32\winevt\Logs" --csv "C:\Forensic_Output\EventLogs" --csvf "All_EventLogs.csv"
```

📸 **Evidence — `EvtxECmd.exe` Lateral Movement & Event ID Correlation:**
> *Place screenshot at:* `../screenshots/dfir02_01_evtxecmd_analysis.png`  
> ![EvtxECmd Event Log Analysis](../screenshots/dfir02_01_evtxecmd_analysis.png)

