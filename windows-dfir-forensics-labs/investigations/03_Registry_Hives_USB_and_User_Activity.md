# Investigation Playbook 03: Registry Forensics, Dirty Hive Replay, User Activity & USB Tracking

| Metadata | Details |
| :--- | :--- |
| **DFIR Domain** | Registry Hives, User Knowledge of Files/Folders & Removable Media Attribution |
| **Artifacts Covered** | `NTUSER.DAT`, `UsrClass.dat` (Shellbags), `.LNK` Shortcut Files, Jump Lists (`*.automaticDestinations-ms`), `SYSTEM` (`USBSTOR` & `MountedDevices`) |
| **Forensic Tooling** | `Registry Explorer`, `SBECmd.exe`, `LECmd.exe`, `JLECmd.exe` |

---

## 🎯 1. Investigative Objective

When investigating insider data theft or interactive attacker staging, examiners must prove **which folders a user navigated inside Windows Explorer (even if those folders were on an encrypted container or external USB drive that has since been removed), which files they opened, and the exact make, serial number, and connection timestamps of every USB storage device connected to the host**.

---

## 🔬 2. Core Artifact Analysis & Commands

### A. Dirty Registry Hive Transaction Log Replay (`.LOG1` / `.LOG2`)
- **Critical Forensic Principle:** When acquiring a live triage image (e.g., via KAPE or FTK Imager), recent registry modifications reside in uncommitted transaction logs (`NTUSER.DAT.LOG1`, `SYSTEM.LOG1`, etc.) rather than the primary hive file.
- Parsing a registry hive without replaying its `.LOG1`/`.LOG2` files causes the examiner to miss recent persistence keys (`Run`/`RunOnce`), recent `UserAssist` updates, or recent USB connections, and yields sequence number mismatch warnings.

---

### B. Shellbags (`UsrClass.dat` & `NTUSER.DAT` — `BagMRU` / `Bags`)
- **Forensic Value:** Windows stores folder view preferences (icon size, sort order, window position) whenever a user expands or navigates into a directory using **Windows Explorer**.
- **Anti-Forensic Resilience:** Deleting a folder from the hard drive or unplugging a USB drive **does not delete its Shellbag entry**. Shellbags prove that a specific user account interactively browsed a directory structure (including network shares, ZIP archives, and removable drives).

```powershell
# Parse Shellbags across all user profiles using SBECmd.exe
SBECmd.exe -d "C:\Users" --csv "C:\Forensic_Output\Shellbags"
```

📸 **Evidence — `SBECmd.exe` / `Registry Explorer` Shellbag Directory Reconstruction:**
> *Place screenshot at:* `../screenshots/dfir03_01_shellbags_analysis.png`  
> ![Shellbags Analysis](../screenshots/dfir03_01_shellbags_analysis.png)

---

### C. Windows Shortcut Files (`.LNK`) & Jump Lists (`*.automaticDestinations-ms`)
- **`.LNK` Files (`%APPDATA%\Microsoft\Windows\Recent\`):** Automatically generated when a user opens a non-executable document or double-clicks an item in Explorer. Captures:
  - Target file's **Creation, Modification, and Access timestamps** at the moment the link was updated
  - Target file size and MFT Entry/Sequence number
  - **Volume Name, Drive Type, and Volume Serial Number**
  - **NetBIOS Machine Name & MAC Address** (embedded inside the Distributed Link Tracking `Droid` GUID)
- **Jump Lists (`%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\`):** OLE Compound Files containing numbered streams (each an embedded `.LNK` structure) plus a **`DestList` stream** tracking pin status, access count, and last access time per application (`AppId`).

```powershell
# Parse all .LNK files and Jump Lists
LECmd.exe -d "C:\Users" --csv "C:\Forensic_Output\LNK" -q
JLECmd.exe -d "C:\Users" --csv "C:\Forensic_Output\JumpLists" -q
```

📸 **Evidence — `LECmd.exe` & `JLECmd.exe` Target Metadata Extraction:**
> *Place screenshot at:* `../screenshots/dfir03_02_lnk_jumplist_analysis.png`  
> ![LNK and JumpList Analysis](../screenshots/dfir03_02_lnk_jumplist_analysis.png)

---

### D. USB Device Tracking (`SYSTEM\CurrentControlSet\Enum\USBSTOR` & `USB`)
To attribute removable media data exfiltration, correlate four artifacts:
1. **Vendor, Product, Version & Unique Serial Number:** `SYSTEM\CurrentControlSet\Enum\USBSTOR\Disk&Ven_<Vendor>&Prod_<Product>&Rev_<Ver>\<SerialNumber>` *(Note: If the second character of the instance ID is `&`, the device lacks a hardware serial number and Windows generated a bus-specific ID).*
2. **Drive Letter & Volume GUID Mapping:** `SYSTEM\MountedDevices` (`\DosDevices\E:` mapped to device signature/GUID) and `SOFTWARE\Microsoft\Windows Portable Devices\Devices`.
3. **USB Connection & Removal Property Keys (`USBSTOR\...\Properties\{83da6326-97a6-4088-9453-a19231573b29}\`):**
   - **`0064`:** First Install Timestamp
   - **`0066`:** Last Arrival (Last Connected) Timestamp
   - **`0067`:** Last Removal (Last Disconnected) Timestamp
4. **User Attribution:** Correlate the Volume GUID against a specific user's `NTUSER.DAT\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\{Volume-GUID}`.

