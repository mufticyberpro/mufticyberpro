# 📸 Screenshot Evidence Directory (`windows-dfir-forensics-labs`)

As you run your Windows Forensics tools (Eric Zimmerman Tools, Timeline Explorer, Registry Explorer, Autopsy, Volatility), save your screenshots here with these filenames so they automatically render inside the 5 Investigation Playbooks:

| Investigation Playbook | Filename to Save in `screenshots/` | What to Capture |
| :---: | :--- | :--- |
| **Playbook 01** | `dfir01_01_pecmd_prefetch.png` | `PECmd.exe` output or Timeline Explorer showing Prefetch run counts & last 8 timestamps |
| **Playbook 01** | `dfir01_02_srum_network_usage.png` | `SrumECmd.exe` output in Timeline Explorer showing Application resource/network bytes sent |
| **Playbook 02** | `dfir02_01_evtxecmd_analysis.png` | `EvtxECmd.exe` or Event Viewer showing Event IDs `4624` (LogonType 10/3), `7045`, or `4104` |
| **Playbook 03** | `dfir03_01_shellbags_analysis.png` | `SBECmd.exe` or Registry Explorer showing Shellbags directory hierarchy |
| **Playbook 03** | `dfir03_02_lnk_jumplist_analysis.png` | `LECmd.exe` / `JLECmd.exe` showing `.LNK` target path, MACB timestamps, and Volume Serial |
| **Playbook 04** | `dfir04_01_mftecmd_timestomp.png` | `MFTECmd.exe` in Timeline Explorer comparing `$SI` (`0x10`) vs `$FN` (`0x30`) timestamps |
| **Playbook 05** | `dfir05_01_browser_and_zone_identifier.png` | Browser SQLite `History`/`downloads` table or PowerShell `-Stream Zone.Identifier` output |

