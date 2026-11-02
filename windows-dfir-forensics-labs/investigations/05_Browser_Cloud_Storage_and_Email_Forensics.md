# Investigation Playbook 05: Browser Forensics, Cloud Storage Sync & Email Header Investigation

| Metadata | Details |
| :--- | :--- |
| **DFIR Domain** | Initial Access, Web Downloads, Cloud Sync & Phishing Attribution |
| **Artifacts Covered** | Chromium/Firefox SQLite Databases (`History`, `downloads`, `.sqlite-wal`), `:Zone.Identifier` ADS, OneDrive `.odl` / `SyncEngineDatabase.db`, RFC 5322 Email Headers |
| **Forensic Tooling** | `SQLECmd.exe`, `DB Browser for SQLite`, PowerShell `Get-Content -Stream Zone.Identifier` |

---

## 🎯 1. Investigative Objective

Most endpoint compromises begin with a web download or a spearphishing email, and end with cloud data exfiltration (OneDrive, Google Drive, Dropbox). This playbook establishes how to trace the **exact source URL and referrer of downloaded payloads, recover deleted browser activity from SQLite Write-Ahead Logs (`.wal`), audit cloud synchronization logs, and authenticate email headers (`SPF`, `DKIM`, `DMARC`)**.

---

## 🔬 2. Core Artifact Analysis & Commands

### A. Chromium (`Chrome` / `Edge`) & Firefox SQLite Forensics
- **Chromium Profile Path:** `%LOCALAPPDATA%\Google\Chrome\User Data\Default\` (or `%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\`)
  - **`History` SQLite Database:**
    - `urls` table: URL, Page Title, Visit Count, Typed Count, Last Visit Time (*WebKit/Chrome timestamp: microseconds since January 1, 1601 UTC*).
    - `visits` table: Transition type (`LINK`, `TYPED`, `RELOAD`, `FORM_SUBMIT`) and referrer visit ID.
    - `downloads` & `downloads_url_chains` tables: Target file path, total bytes, start/end timestamps, interrupt reason, and full redirect URL chain.
- **SQLite Write-Ahead Log (`.sqlite-wal` / `-wal`) Pitfall:**
  - Modern browsers operate SQLite in **WAL mode**. If an examiner copies only the `History` or `places.sqlite` file without copying the accompanying `-wal` and `-shm` files from the same directory, recently visited URLs and recently deleted records sitting in uncommitted WAL frames will be lost!

---

### B. NTFS Alternate Data Streams — `:Zone.Identifier` (Mark-of-the-Web)
When a file is downloaded via a browser, email client, or archive extractor that respects Mark-of-the-Web (MotW), Windows attaches an NTFS Alternate Data Stream named **`Zone.Identifier`** to the file:

```powershell
# Inspect the Zone.Identifier Alternate Data Stream on a downloaded executable
Get-Content -Path "C:\Users\Victim\Downloads\invoice_update.zip" -Stream Zone.Identifier
```

#### Example Forensic Output:
```ini
[ZoneTransfer]
ZoneId=3
ReferrerUrl=https://mail.attacker-portal.example/webmail/inbox
HostUrl=https://cdn.attacker-portal.example/payloads/invoice_update.zip
```
- **ZoneId Mapping:** `0` = Local Machine, `1` = Local Intranet, `2` = Trusted Sites, **`3` = Internet**, `4` = Restricted Sites.

📸 **Evidence — Browser SQLite & `:Zone.Identifier` ADS Analysis:**
> *Place screenshot at:* `../screenshots/dfir05_01_browser_and_zone_identifier.png`  
> ![Browser and Zone Identifier Analysis](../screenshots/dfir05_01_browser_and_zone_identifier.png)

---

### C. Cloud Storage Forensics (Microsoft OneDrive)
- **Key Locations (`%LOCALAPPDATA%\Microsoft\OneDrive\`):**
  - **`logs\Business1\*.odl` / `logs\Personal\*.odl`:** Obfuscated OneDrive diagnostic logs tracking file uploads, downloads, deletions, and sharing operations.
  - **`settings\Business1\SyncEngineDatabase.db` / `SafeDelete.db`:** Tracks synced cloud file metadata, SHA-256/`quickXorHash` hashes, and cloud-to-local file state.
- **NTFS Reparse Points (Files On-Demand):** Files marked with the `IO_REPARSE_TAG_CLOUD` attribute exist as metadata placeholders (`0 bytes` allocated on local disk clusters) until hydrated/opened by the user.

---

### D. RFC 5322 Email Header & Authentication Analysis
- **Reading `Received:` Hop Headers:** Always read `Received:` headers **from bottom (originating sender mail server) to top (final recipient mail gateway)**. Adversaries can forge the topmost/earliest custom headers (`X-Originating-IP` or `From:`), but cannot forge the `Received:` header stamped by the receiving enterprise mail transfer agent (MTA).
- **Authentication-Results Verification:**
  - **SPF (Sender Policy Framework):** Validates whether the connecting MTA's IP address is authorized in the sender domain's DNS TXT record (`Return-Path` / Envelope Sender).
  - **DKIM (DomainKeys Identified Mail):** Validates the cryptographic signature (`DKIM-Signature:`) covering the message body and selected headers against the public key published in the sender domain's DNS.
  - **DMARC:** Enforces alignment between the human-visible `From:` header domain and the authenticated `SPF` and/or `DKIM` domain.

