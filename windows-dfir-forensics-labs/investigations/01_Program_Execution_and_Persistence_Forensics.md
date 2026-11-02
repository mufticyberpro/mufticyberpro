# Investigation Playbook 01: Program Execution, Persistence & Resource Usage Reconstruction

| Metadata | Details |
| :--- | :--- |
| **DFIR Domain** | Evidence of Execution & Process Attribution |
| **Artifacts Covered** | Windows Prefetch (`C:\Windows\Prefetch\*.pf`), `Amcache.hve`, `AppCompatCache` (Shimcache), `BAM`/`DAM`, and `SRUDB.dat` (SRUM) |
| **Forensic Tooling** | `PECmd.exe`, `AmcacheParser.exe`, `AppCompatCacheParser.exe`, `SrumECmd.exe`, `Timeline Explorer` |

---

## 🎯 1. Investigative Objective

When an attacker stages and executes a malicious binary (e.g., `mimikatz.exe` or a custom data exfiltrator) and immediately deletes the executable from disk, file system scans alone will miss the execution details. This playbook establishes how to prove **whether a binary executed, how many times it ran, the exact timestamps of its last 8 executions, its SHA-1 cryptographic hash, and the exact volume of network bytes it transmitted**.

---

## 🔬 2. Core Artifact Analysis & Commands

### A. Windows Prefetch (`C:\Windows\Prefetch\<EXENAME>-<HASH>.pf`)
- **Forensic Value:** Proves actual **execution**. Windows 10/11 (Prefetch Version 30, MAM-compressed) tracks:
  - Total **Run Count**
  - **Last 8 Execution Timestamps** (Index `0` = Most Recent Execution; up to 7 historical slots)
  - Full list of **files and directories referenced** during the first 10 seconds of process startup (crucial for discovering dropped payloads or config files even after deletion).

```powershell
# Parse an entire Prefetch directory using Eric Zimmerman's PECmd.exe
PECmd.exe -d "C:\Windows\Prefetch" --csv "C:\Forensic_Output\Prefetch" --csvf "Prefetch_Analysis.csv" -q
```

📸 **Evidence — `PECmd.exe` Output & Timeline Explorer Inspection:**
> *Place screenshot at:* `../screenshots/dfir01_01_pecmd_prefetch.png`  
> ![PECmd Prefetch Analysis](../screenshots/dfir01_01_pecmd_prefetch.png)

---

### B. `Amcache.hve` (`C:\Windows\AppCompat\Programs\Amcache.hve`)
- **Forensic Value:** Records executable metadata inside the `Root\InventoryApplicationFile` subkey:
  - **SHA-1 Hash** (`FileId` value with a `0000` prefix stripped)
  - Full file path, file size, publisher, and PE header `CompileTime`
  - Key Last Write timestamp (correlates with first execution or application discovery)

```powershell
# Parse Amcache.hve with transaction log replay enabled
AmcacheParser.exe -f "C:\Windows\AppCompat\Programs\Amcache.hve" --csv "C:\Forensic_Output\Amcache" -i
```

---

### C. `AppCompatCache` / Shimcache (`SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache`)
- **Forensic Value:** Stored inside the `SYSTEM` registry hive and flushed from kernel memory to disk cleanly upon system shutdown/reboot.
- **Critical Analyst Distinction:** On Windows 10/11, Shimcache records **File Path, File Size, and File Last Modified (`$STANDARD_INFORMATION` Modified) Timestamp**. Unlike Windows 7/8, Windows 10/11 Shimcache does not contain an explicit "Executed" flag—meaning presence proves **file existence/inspection**, and should be paired with `Prefetch`, `BAM`, or `SRUM` to confirm execution.

```powershell
# Parse Shimcache from the SYSTEM registry hive
AppCompatCacheParser.exe -f "C:\Windows\System32\config\SYSTEM" --csv "C:\Forensic_Output\Shimcache"
```

---

### D. System Resource Usage Monitor — SRUM (`C:\Windows\System32\sru\SRUDB.dat`)
- **Forensic Value:** An ESE database updated hourly (and at shutdown) that connects **User SID**, **Application Path**, **CPU Cycle Time**, and **Network Bytes Sent / Received** (`{973F5D5C-1D90-4944-BE8E-24B94231A174}`).
- Even if an attacker deletes their exfiltration binary and clears event logs, `SRUDB.dat` reveals the exact process path, the user SID that ran it, and the megabytes/gigabytes uploaded over the network interface.

```powershell
# Parse SRUDB.dat alongside the SOFTWARE hive (for network profile & SID resolution)
SrumECmd.exe -f "C:\Windows\System32\sru\SRUDB.dat" -r "C:\Windows\System32\config\SOFTWARE" --csv "C:\Forensic_Output\SRUM"
```

📸 **Evidence — `SrumECmd.exe` Network Exfiltration & Application Resource Attribution:**
> *Place screenshot at:* `../screenshots/dfir01_02_srum_network_usage.png`  
> ![SRUM Analysis](../screenshots/dfir01_02_srum_network_usage.png)

---

## 📊 3. Execution Artifacts Comparison Matrix

| Artifact | Proves Execution? | Stores File Hash? | Tracks Run Count? | Tracks Network Bytes? |
| :--- | :---: | :---: | :---: | :---: |
| **Prefetch (`*.pf`)** | ✅ Yes | ❌ (Path Hash only) | ✅ Yes (+ Last 8 runs) | ❌ No |
| **`Amcache.hve`** | ⚠️ Presence / First Run | ✅ **SHA-1** | ❌ No | ❌ No |
| **Shimcache (`SYSTEM`)** | ⚠️ File Presence | ❌ No | ❌ No | ❌ No |
| **`BAM` / `DAM` (`SYSTEM`)** | ✅ Yes | ❌ No | ❌ (Last execution per SID) | ❌ No |
| **SRUM (`SRUDB.dat`)** | ✅ Yes | ❌ No | ⚠️ Resource intervals | ✅ **Bytes Sent/Received** |

