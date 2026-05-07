<!-- Copy this template into each Lab/<Lab_Name>/README.md and fill it in -->

# 🧪 [Lab Name] — e.g., Nmap Network Scanning & Enumeration

## 🎯 Objective
What this lab demonstrates and what skill it proves. (1–2 sentences.)

> Example: Demonstrate host discovery, service/version detection, and OS fingerprinting against a controlled lab network using Nmap.

---

## 🛠️ Environment

| Component | Details |
|----------|---------|
| Attacker | Kali Linux 2024.x (VirtualBox) |
| Target   | Metasploitable 2 / Windows Server 2022 |
| Network  | Host-only adapter, 192.168.56.0/24 |
| Tools    | Nmap 7.94, Wireshark (verification) |

---

## 📋 Steps & Commands

### 1. Host discovery
```bash
nmap -sn 192.168.56.0/24
```
**Screenshot:** `screenshots/01-host-discovery.png`

![Host discovery](./screenshots/01-host-discovery.png)

**What I observed:** Identified 3 live hosts on the subnet, including the target at 192.168.56.101.

---

### 2. Service & version detection
```bash
nmap -sV -p- 192.168.56.101
```
**Screenshot:** `screenshots/02-service-version.png`

![Service detection](./screenshots/02-service-version.png)

**What I observed:** Open ports include 21 (vsftpd 2.3.4 — known backdoor), 22 (OpenSSH 4.7), 80 (Apache 2.2.8).

---

### 3. OS fingerprinting & NSE scripts
```bash
nmap -O --script vuln 192.168.56.101
```
**Screenshot:** `screenshots/03-os-and-vuln-scripts.png`

![OS and vuln](./screenshots/03-os-and-vuln-scripts.png)

**What I observed:** OS identified as Linux 2.6.x. NSE flagged CVE-2011-2523 (vsftpd backdoor).

---

## 🔍 Findings

- **Critical:** vsftpd 2.3.4 backdoor (CVE-2011-2523) — exploitable, immediate remediation needed.
- **High:** Outdated OpenSSH 4.7 — known to allow user enumeration.
- **Medium:** Apache 2.2.8 — multiple known CVEs in this version.

---

## ✅ Lessons Learned

- The difference between `-sS` (stealth SYN) and `-sT` (full TCP connect) and when each is appropriate.
- Why credentialed/authenticated scanning gives better results than unauthenticated.
- How to validate Nmap output by cross-checking with Wireshark captures.

---

## 📎 Files in This Lab

- `README.md` — this writeup
- `screenshots/` — annotated evidence
- `nmap-scan.txt` — raw scan output
- `notes.md` — additional notes and references
