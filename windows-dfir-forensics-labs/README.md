# 🔎 Windows Digital Forensics & Incident Response (DFIR) Playbooks

[![Windows Forensics](https://img.shields.io/badge/DFIR-Windows_Forensic_Analysis-1E293B?style=for-the-badge&logo=windows&logoColor=white)](#)
[![Zimmerman Tools](https://img.shields.io/badge/Tooling-Eric_Zimmerman_Suite-0F172A?style=for-the-badge)](#)
[![Volatility](https://img.shields.io/badge/Memory_Forensics-Volatility_3-B91C1C?style=for-the-badge)](#)
[![Autopsy](https://img.shields.io/badge/Disk_Analysis-NTFS_%2F_MFT_%2F_Registry-0078D4?style=for-the-badge)](#)

> **Author:** Muftaw Wahab Ayinla (MSc Cybersecurity)  
> **Forensic Focus:** Windows Endpoint Triage, Program Execution Reconstruction, Registry Hive & Transaction Log Analysis, Lateral Movement Event Log Correlation, NTFS File System Forensics, and Browser/Cloud Exfiltration Analysis.

---

## 📌 Executive Overview

When an enterprise Windows host is compromised, anti-forensic cleanup (such as deleting dropped binaries or clearing browser history) rarely removes the underlying operating system telemetry. This repository contains **5 structured Windows Digital Forensics (DFIR) investigation playbooks and artifact reference guides** used to reconstruct adversary activity across disk, registry, event logs, and user profiles.

---

## 🗺️ Windows Forensic Artifact Correlation Matrix

```mermaid
flowchart TB
    subgraph Q1["1. Initial Access & Delivery"]
        Email["Email & Attachment Artifacts<br/>(RFC 5322 Headers, SPF/DKIM/DMARC, PST/OST)"]
        Zone["Browser & Zone.Identifier ADS<br/>(History SQLite, HostUrl, ReferrerUrl)"]
    end

    subgraph Q2["2. Program Execution & Persistence"]
        Exec["Execution Artifacts<br/>(Prefetch .pf, Amcache.hve, Shimcache, BAM/DAM)"]
        SRUM["Resource & Network Attribution<br/>(SRUDB.dat App Timeline & Bytes Sent)"]
    end

    subgraph Q3["3. Interactive Activity & File Knowledge"]
        User["Shell Items & User Hives<br/>(NTUSER.DAT, UsrClass.dat Shellbags, LNK, JumpLists)"]
        USB["External Device Tracking<br/>(SYSTEM USBSTOR 0064/0066/0067, SetupAPI)"]
    end

    subgraph Q4["4. Lateral Movement & Anti-Forensics"]
        Evt["Windows Event Logs (.evtx)<br/>(Security 4624/4688/1102, System 7045, RDP 21-25)"]
        NTFS["NTFS File System & Timestomping<br/>($MFT $SI vs $FN, $UsnJrnl:$J, VSS)"]
    end

    Q1 --> Q2 --> Q3 --> Q4
```

---

## 📂 Forensic Investigation Playbooks (`investigations/`)

| # | Investigation Playbook | Primary Forensic Artifacts Analyzed | Core Forensic Tooling |
| :---: | :--- | :--- | :--- |
| **01** | **[Program Execution, Persistence & Resource Usage Reconstruction](./investigations/01_Program_Execution_and_Persistence_Forensics.md)** | Windows Prefetch (`v26`/`v30`), `Amcache.hve` (`InventoryApplicationFile`), `AppCompatCache` (Shimcache), `BAM`/`DAM`, and `SRUDB.dat` (SRUM) | `PECmd.exe`, `AmcacheParser.exe`, `AppCompatCacheParser.exe`, `SrumECmd.exe` |
| **02** | **[Windows Event Log Correlation & Lateral Movement Triage](./investigations/02_Event_Log_and_Lateral_Movement_Investigation.md)** | `Security.evtx` (`4624`, `4625`, `4648`, `4672`, `4688`, `1102`), `System.evtx` (`7045`), TerminalServices RDP (`21`, `22`, `24`, `25`, `1149`), PowerShell (`4104`) | `EvtxECmd.exe`, Timeline Explorer, Event Viewer |
| **03** | **[Registry Forensics, Dirty Hive Replay, User Activity & USB Tracking](./investigations/03_Registry_Hives_USB_and_User_Activity.md)** | Dirty Registry Transaction Logs (`.LOG1`/`.LOG2`), `Shellbags` (`UsrClass.dat`), `.LNK` Shortcut Files & Volume Serials, Jump Lists (`DestList`), and `USBSTOR` (`0064`/`0066`/`0067`) | `Registry Explorer`, `SBECmd.exe`, `LECmd.exe`, `JLECmd.exe` |
| **04** | **[NTFS File System Forensics, Timestomping Detection & Deleted Data Recovery](./investigations/04_NTFS_MFT_UsnJrnl_and_Timestomp_Analysis.md)** | `$MFT` (`$STANDARD_INFORMATION` vs. `$FILE_NAME` MACB drift), Resident vs. Non-Resident `$DATA`, `$UsnJrnl:$J`, Recycle Bin (`$I` / `$R`), Volume Shadow Copies (VSS) | `MFTECmd.exe`, `RBCmd.exe`, Autopsy / FTK Imager |
| **05** | **[Browser Forensics, Cloud Storage Sync & Email Header Investigation](./investigations/05_Browser_Cloud_Storage_and_Email_Forensics.md)** | Chromium/Firefox SQLite (`History`, `urls`, `downloads`, `.sqlite-wal`), `:Zone.Identifier` ADS, OneDrive (`.odl`, `SyncEngineDatabase.db`), RFC 5322 Email Headers | `DB Browser for SQLite`, `SQLECmd.exe`, PowerShell ADS Inspector |

---

## 🛠️ Repository Structure

```text
windows-dfir-forensics-labs/
├── README.md
├── investigations/
│   ├── 01_Program_Execution_and_Persistence_Forensics.md
│   ├── 02_Event_Log_and_Lateral_Movement_Investigation.md
│   ├── 03_Registry_Hives_USB_and_User_Activity.md
│   ├── 04_NTFS_MFT_UsnJrnl_and_Timestomp_Analysis.md
│   └── 05_Browser_Cloud_Storage_and_Email_Forensics.md
└── screenshots/
    └── README.md                            # Evidence directory for Zimmerman Tools / Autopsy / Volatility screenshots
```

