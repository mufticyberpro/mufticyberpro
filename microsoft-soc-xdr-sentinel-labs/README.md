# 🛡️ Microsoft SOC, Detection Engineering, Defender XDR & Sentinel Case Studies

[![Microsoft Sentinel](https://img.shields.io/badge/SIEM-Microsoft_Sentinel-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](#)
[![Microsoft Defender XDR](https://img.shields.io/badge/XDR-Microsoft_Defender_XDR-005BA1?style=for-the-badge&logo=microsoft&logoColor=white)](#)
[![KQL](https://img.shields.io/badge/Query_Language-KQL-0089D6?style=for-the-badge)](#)
[![PowerShell](https://img.shields.io/badge/Purple_Team-PowerShell_Simulations-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](#)
[![MITRE ATT&CK](https://img.shields.io/badge/Framework-MITRE_ATT%26CK-B91C1C?style=for-the-badge)](#)

> **Author:** Muftaw Wahab Ayinla (MSc Cybersecurity)  
> **Lab Environment:** Microsoft Entra ID • Windows 11 Enterprise/Pro • Microsoft Intune • Microsoft Defender XDR • Microsoft Sentinel • Azure Logic Apps • Microsoft Purview

---

## 📌 Overview

This repository documents **7 end-to-end Security Operations Center (SOC) & Detection Engineering case studies** built in a live Microsoft Cloud + Windows 11 environment. Rather than theoretical notes, each case study implements the complete detection and incident response lifecycle:

1. **Preventive Hardening & Policy Engineering** (Intune ASR, Tamper Protection, Purview Sensitivity Labels, Conditional Access App Control).
2. **Safe Purple-Team Adversary Telemetry Generation** (`PowerShell` scripts simulating LOLBAS ingress, Base64 obfuscation, and Scheduled Task persistence).
3. **Detection Engineering** (Custom Scheduled & Near-Real-Time KQL analytics rules with Entity Mapping and Alert Grouping).
4. **Triage, Live Response & Containment** (Attack Story correlation, remote shell forensics, Selective Isolation).
5. **Zero-Trust SOAR Automation** (Sentinel Automation Rules + Azure Logic Apps authenticated via System-Assigned Managed Identity).

---

## 🗺️ Architecture Diagram

```mermaid
flowchart TB
    subgraph Adversary_Sim["1. Purple-Team Telemetry Generation (Windows 11)"]
        S1["test_asr_rules.ps1<br/>(ASR & EventID 1121/1122 Audit)"]
        S2["simulate_suspicious_process.ps1<br/>(T1105 certutil + T1059.001 Encoded PS)"]
        S3["simulate_persistence.ps1<br/>(T1053.005 schtasks Persistence)"]
    end

    subgraph Endpoint_Cloud["2. Endpoint & Cloud Controls"]
        Intune["Microsoft Intune<br/>ASR Rules & Tamper Protection"]
        MDE["Defender for Endpoint Sensor<br/>Live Response & Selective Isolation"]
        MDCA["Defender for Cloud Apps + Purview<br/>Real-Time Session DLP Proxy"]
    end

    subgraph SIEM_XDR["3. Detection & Investigation Engine"]
        XDR["Microsoft Defender XDR<br/>Attack Story & Advanced Hunting"]
        Sentinel["Microsoft Sentinel SIEM<br/>Scheduled & NRT Analytics Rules"]
        Graph["Sentinel Investigation Graph<br/>Host/Account Entity Mapping & Bookmarks"]
    end

    subgraph SOAR["4. Automated Remediation"]
        AutoRule["Sentinel Automation Rule"]
        LogicApp["Azure Logic App Playbook<br/>(System-Assigned Managed Identity)"]
    end

    Adversary_Sim --> MDE
    Intune --> MDE
    MDE -->|DeviceProcessEvents / DeviceEvents| XDR
    MDCA -->|CloudAppEvents| XDR
    XDR <-->|Bi-Directional Incident Sync| Sentinel
    Sentinel --> Graph
    Sentinel --> AutoRule --> LogicApp
    LogicApp -->|RBAC: Sentinel Responder| Sentinel
```

---

## 📂 Case Studies Index

| # | Case Study Report | MITRE ATT&CK Mapping | Core Technologies |
| :---: | :--- | :--- | :--- |
| **01** | **[Endpoint Hardening, Intune ASR Deployment & Tamper Protection](./case-studies/01_Endpoint_Hardening_and_ASR.md)** | `T1003.001` (LSASS Memory)<br/>`T1027` (Obfuscated Scripts)<br/>`T1562.001` (Disable Tools) | Microsoft Intune, MDE, PowerShell (`Get-MpPreference`), KQL (`DeviceEvents`) |
| **02** | **[Incident Triage, Attack Story Correlation & Live Response Containment](./case-studies/02_Incident_Triage_and_LiveResponse.md)** | `T1105` (Ingress Tool Transfer)<br/>`T1059.001` (PowerShell) | Defender XDR Attack Story, Device Timeline, Live Response CLI, Selective Isolation |
| **03** | **[Enterprise SIEM Deployment & Bi-Directional Defender XDR Sync](./case-studies/03_Sentinel_SIEM_and_XDR_Integration.md)** | Enterprise Telemetry & Health Monitoring | Microsoft Sentinel, Log Analytics, Defender XDR Connector, Entra ID Logs, `SentinelHealth` |
| **04** | **[Detection Engineering: Custom Scheduled & NRT KQL Analytics Rules](./case-studies/04_Detection_Engineering_KQL_Analytics.md)** | `T1105` (Ingress Tool Transfer)<br/>`T1059.001` (Encoded Command) | Sentinel Analytics Engine, NRT Rules, Entity Mapping, Alert Grouping, Investigation Graph |
| **05** | **[Zero-Trust SOAR Playbooks with Azure Logic Apps & Managed Identity](./case-studies/05_SOAR_Playbooks_Managed_Identity.md)** | Automated Incident Triage & Enrichment | Sentinel Automation Rules, Azure Logic Apps, System-Assigned Managed Identity, Azure RBAC |
| **06** | **[Proactive Threat Hunting, KQL Regex Extraction & Sentinel Livestream](./case-studies/06_Proactive_Threat_Hunting_KQL.md)** | `T1105`, `T1059.001`, `T1566.001` (Spearphishing Attachment) | KQL Stack Counting (LFO), Multi-Table `inner join`, Hunting Bookmarks, Sentinel Livestream |
| **07** | **[Cloud SaaS DLP: Purview Sensitivity Labels & MDCA Session Control](./case-studies/07_Purview_DLP_and_MDCA_Session_Control.md)** | `T1530` (Data from Cloud Storage) | Microsoft Purview Information Protection, Entra Conditional Access, Defender for Cloud Apps (`*.mcas.ms`) |

---

## 🛠️ Repository Structure

```text
microsoft-soc-xdr-sentinel-labs/
├── README.md
├── case-studies/
│   ├── 01_Endpoint_Hardening_and_ASR.md
│   ├── 02_Incident_Triage_and_LiveResponse.md
│   ├── 03_Sentinel_SIEM_and_XDR_Integration.md
│   ├── 04_Detection_Engineering_KQL_Analytics.md
│   ├── 05_SOAR_Playbooks_Managed_Identity.md
│   ├── 06_Proactive_Threat_Hunting_KQL.md
│   └── 07_Purview_DLP_and_MDCA_Session_Control.md
├── queries/
│   └── hunting_queries.kql                  # 7 Production KQL Hunting & Analytics Queries
├── simulations/
│   ├── test_asr_rules.ps1                   # Local ASR GUID mapper, Tamper check & EventID 1121/1122 parser
│   ├── simulate_suspicious_process.ps1      # Safe LOLBAS certutil + Base64 PowerShell telemetry generator
│   └── simulate_persistence.ps1             # Safe Scheduled Task (schtasks.exe) persistence generator
└── screenshots/
    └── README.md                            # Organized evidence directory for lab execution screenshots
```

---

## 🔍 Quick Preview: Production KQL & Simulation Tooling

### 1. Extracting Base64-Encoded PowerShell Payloads (`queries/hunting_queries.kql`)
```kql
DeviceProcessEvents
| where TimeGenerated >= ago(7d)
| where FileName in~ ("powershell.exe", "pwsh.exe")
| where ProcessCommandLine has_any ("-e ", "-enc ", "-encodedcommand ", "-ec ")
| extend ExtractedBase64 = extract(@"-(?:e|enc|encodedcommand|ec)\s+([A-Za-z0-9+/=]+)", 1, ProcessCommandLine)
| project TimeGenerated, DeviceName, AccountName, ProcessCommandLine, ExtractedBase64, InitiatingProcessFileName
| sort by TimeGenerated desc
```

### 2. Local ASR Policy & Event ID 1121/1122 Verification (`simulations/test_asr_rules.ps1`)
```powershell
# Inspects local Windows 11 Defender ASR rules, maps GUIDs to human-readable names,
# verifies Tamper Protection state, and queries Microsoft-Windows-Windows Defender/Operational
.\simulations\test_asr_rules.ps1
```

