# Investigation Playbook 04: NTFS File System Forensics, Timestomping Detection & Deleted Data Recovery

| Metadata | Details |
| :--- | :--- |
| **DFIR Domain** | NTFS File System Internals & Anti-Forensics Detection |
| **Artifacts Covered** | `$MFT` (`$STANDARD_INFORMATION` vs. `$FILE_NAME`), `$UsnJrnl:$J`, `$LogFile`, Recycle Bin (`$I` / `$R`), Volume Shadow Copies (VSS) |
| **Forensic Tooling** | `MFTECmd.exe`, `RBCmd.exe`, `Autopsy`, `Timeline Explorer` |

---

## 🎯 1. Investigative Objective

Sophisticated adversaries frequently use **Timestomping** utilities (such as `timestomp.exe` or PowerShell `(Get-Item $file).CreationTime = ...`) to backdate malicious DLLs or scripts so they blend in with legitimate Windows `System32` binaries, and subsequently delete staging files after execution. This playbook outlines how to detect timestamp manipulation and recover deleted metadata using NTFS transactional structures.

---

## 🔬 2. Core Artifact Analysis & Commands

### A. `$MFT` Analysis & Detecting Timestomping (`$STANDARD_INFORMATION` vs. `$FILE_NAME`)
Every file and directory on an NTFS volume is represented by a **1,024-byte (1 KB) record** in the Master File Table (`$MFT`), which contains two independent sets of MACB (Modified, Accessed, MFT Entry Modified, Created/Born) timestamps:
1. **`$STANDARD_INFORMATION` (`$SI`, Attribute `0x10`):** Displayed by Windows Explorer and standard `dir` commands. User-mode processes and administrative scripts can modify `$SI` timestamps at will via standard Win32 API calls (`SetFileTime`).
2. **`$FILE_NAME` (`$FN`, Attribute `0x30`):** Maintained strictly by the Windows NTFS kernel driver (`ntfs.sys`) when a file is created, moved, or renamed. Standard user-mode timestomping tools cannot directly overwrite `$FN` timestamps.

#### Key Indicators of Timestomping in `MFTECmd.exe` Output:
- **Clock Rollback:** `$SI` Created (`Created0x10`) is **earlier** than `$FN` Created (`Created0x30`) — e.g., `$SI` claims the binary was created in `2019`, whereas `$FN` proves the file was actually created on the volume during last night's intrusion.
- **Zeroed Sub-Second Precision (`Zeroed Nanoseconds`):** NTFS records 100-nanosecond intervals (7 decimal places). Legacy timestomping utilities often pass timestamps with `.0000000` fractional seconds in `$SI` while `$FN` retains authentic sub-second entropy.

```powershell
# Parse the NTFS $MFT and $UsnJrnl:$J using MFTECmd.exe
MFTECmd.exe -f "E:\$MFT" --csv "C:\Forensic_Output\NTFS" --csvf "MFT_Parsed.csv"
MFTECmd.exe -f "E:\$Extend\$UsnJrnl:$J" -m "E:\$MFT" --csv "C:\Forensic_Output\NTFS" --csvf "UsnJrnl_Parsed.csv"
```

📸 **Evidence — `MFTECmd.exe` Timestomping Detection (`0x10` vs. `0x30` Drift):**
> *Place screenshot at:* `../screenshots/dfir04_01_mftecmd_timestomp.png`  
> ![MFTECmd Timestomp Analysis](../screenshots/dfir04_01_mftecmd_timestomp.png)

---

### B. Resident vs. Non-Resident `$DATA` (`0x80`) Attributes
- **Resident Data:** If a file's contents are smaller than approximately **700 bytes**, NTFS stores the entire file payload **directly inside the 1,024-byte `$MFT` record** itself (Resident `$DATA`) rather than allocating external disk clusters.
- **Forensic Impact:** Small batch scripts (`.bat`), PowerShell one-liners (`.ps1`), or attacker credential notes are frequently recoverable in full directly from the `$MFT` even when external cluster carving fails.

---

### C. Change Journal (`$Extend\$UsnJrnl:$J`) & Recycle Bin (`$Recycle.Bin\<SID>\`)
- **`$UsnJrnl:$J`:** Tracks chronological file creation (`FileCreate`), content modification (`DataOverwrite` / `DataExtend`), renaming (`RenameOldName` / `RenameNewName`), and deletion (`FileDelete`) across the volume.
- **Recycle Bin (`$Ixxxxxx` vs. `$Rxxxxxx`):**
  - **`$I` (Metadata Index File):** Contains the **Original File Path**, **Original File Size**, and **Deletion Timestamp**.
  - **`$R` (Recovery Data File):** Contains the actual raw file contents.

```powershell
# Parse all Recycle Bin $I metadata files across all User SIDs
RBCmd.exe -d "C:\$Recycle.Bin" --csv "C:\Forensic_Output\RecycleBin"
```

