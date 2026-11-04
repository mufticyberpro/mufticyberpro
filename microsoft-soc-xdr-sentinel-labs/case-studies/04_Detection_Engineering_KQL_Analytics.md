# Case Study 04: Detection Engineering — Custom Scheduled & NRT KQL Analytics Rules

| Metadata | Details |
| :--- | :--- |
| **Role Focus** | Detection Engineer / SOC Analyst |
| **MITRE ATT&CK** | `T1105` (Ingress Tool Transfer), `T1059.001` (PowerShell `-EncodedCommand`) |
| **Target Host** | `securitydesktop` (Windows 11 64-bit) |
| **SIEM / XDR Platform** | Microsoft Sentinel Analytics Engine & Unified Defender XDR Incident Graph |
| **Automation / Query Assets** | [`simulations/simulate_suspicious_process.ps1`](../simulations/simulate_suspicious_process.ps1), [`queries/hunting_queries.kql`](../queries/hunting_queries.kql) |

---

## 🎯 1. Objective & Problem Statement

Raw telemetry stored in a SIEM has zero defensive value until Detection Engineers translate adversary tradecraft into high-fidelity **Analytics Rules**. However, poorly engineered rules suffer from two major operational flaws:
1. **Unmapped Entities:** Alerts trigger as flat text without linking the affected `Host`, `Account`, or `IP`, leaving Tier 1 analysts unable to pivot in the **Incident / Investigation Graph**.
2. **Alert Fatigue:** Rapid script execution triggers dozens of duplicate tickets within minutes if **Alert Grouping** is not configured.

**Detection Engineering Objective:**
1. Author a **Scheduled Analytics Rule** in KQL (`SecOps - Suspicious Living-off-the-Land Ingress Tool Transfer (certutil.exe)`) to detect Living-off-the-Land payload staging (`T1105`).
2. Configure **Entity Mapping** (`HostName = DeviceName` and `Account Name = AccountName`) and **Ingestion Latency Lookback Buffering** (1-hour frequency with a 2-hour lookback window).
3. Configure **Alert Grouping** to consolidate related alerts on the same host within a 2-hour window into a single incident.
4. Author a **Near-Real-Time (NRT) Analytics Rule** (`SecOps - NRT - Critical Encoded PowerShell Execution`) executing every **60 seconds** to detect Base64-encoded PowerShell execution (`T1059.001`).
5. Trigger the detections using [`simulate_suspicious_process.ps1`](../simulations/simulate_suspicious_process.ps1) on `securitydesktop` and validate entity correlation in the **Incident Graph**.

---

## 🏗️ 2. Detection Engineering Pipeline

```mermaid
flowchart TD
    Logs["Ingested Telemetry<br/>(DeviceProcessEvents)"] --> Sched["Scheduled KQL Rule<br/>(Freq: 1h | Lookback: 2h)<br/>Detects certutil.exe -urlcache"]
    Logs --> NRT["Near-Real-Time (NRT) Rule<br/>(Executes Every 60 Seconds)<br/>Detects Encoded PowerShell"]
    Sched --> Entities["Entity Mapping<br/>Host (HostName = DeviceName)<br/>Account (Name = AccountName)"]
    NRT --> Entities
    Entities --> Grouping["Alert Grouping Engine<br/>Consolidate matching Host alerts (2h window)"]
    Grouping --> Graph["Microsoft Sentinel / Unified XDR Incident<br/>& Interactive Incident Graph"]
```

---

## 🛠️ 3. Detection Rule Engineering & Validation

### Phase 1: Authoring the Scheduled KQL Analytics Rule (`T1105`)
In **Microsoft Sentinel** > **Configuration** > **Analytics** > **+ Create > Scheduled query rule**, I engineered the rule:

- **Name:** `SecOps - Suspicious Living-off-the-Land Ingress Tool Transfer (certutil.exe)`
- **Description:** `Detects certutil.exe invoked with -urlcache or -split command-line arguments to download remote payloads.`
- **Tactics & Techniques:** `2 Selected` (`Command and Control`, `Execution` — `T1105 Ingress Tool Transfer`)
- **Severity:** `Medium`
- **Status:** `Enabled`

📸 **Evidence — Scheduled Analytics Rule General Configuration & MITRE Mapping:**

![Scheduled Rule General Details](../screenshots/case04_01_scheduled_rule_logic.png)

#### Detection KQL Logic & Entity Mapping:
```kql
DeviceProcessEvents
| where TimeGenerated >= ago(1h)
| where FileName =~ "certutil.exe"
| where ProcessCommandLine has_any ("-urlcache", "-split")
| project TimeGenerated, DeviceName, AccountName, ProcessCommandLine, InitiatingProcessFileName, InitiatingProcessCommandLine, FolderPath
```

| Entity Type | Identifier | Mapped KQL Column |
| :--- | :--- | :--- |
| **Host** | `HostName` | `DeviceName` |
| **Account** | `Name` | `AccountName` |

#### Scheduling & Alert Grouping (Anti-Fatigue Tuning):
- **Query Frequency:** Run every `1 Hour`
- **Lookup Data Window:** Last `2 Hours` *(prevents missed detections caused by cloud ingestion delay)*
- **Alert Grouping:** Enabled — consolidates all alerts triggered within a **2-hour window** into a single incident when the **Host** entity matches.

📸 **Evidence — Scheduled Rule KQL Query & Host/Account Entity Mapping:**

![Scheduled Rule Logic & Entity Mapping](../screenshots/case04_01_scheduled_rule_logic2.png)

---

### Phase 2: Authoring a 60-Second Near-Real-Time (NRT) Rule (`T1059.001`)
For high-velocity threats where a 5-to-60 minute scheduled interval is too slow, I created a **Near-Real-Time (NRT)** rule (**+ Create > NRT query rule**):

- **Name:** `SecOps - NRT - Critical Encoded PowerShell Execution`
- **Severity:** `High`
- **Status:** `Enabled`
- **Architectural Constraint Handled:** Adhered to Sentinel NRT engine requirements by querying a single table (`DeviceProcessEvents`) without `join` or `union` operators for sub-minute execution, with `Event grouping` set to `Trigger an alert for each event`.

```kql
DeviceProcessEvents
| where FileName in~ ("powershell.exe", "pwsh.exe")
| where ProcessCommandLine has_any ("-enc ", "-encodedcommand ", "-ec ")
| project TimeGenerated, DeviceName, AccountName, ProcessCommandLine
```

📸 **Evidence — NRT Analytics Rule General Configuration (`Severity: High`):**

![NRT Rule General Config](../screenshots/case04_02_nrt_rule_config.png)

📸 **Evidence — NRT Single-Table KQL Rule Logic & Event Grouping:**

![NRT Rule Query Logic](../screenshots/case04_02_nrt_rule_config2.png)

---

### Phase 3: Triggering the Detection & Incident Graph Analysis
1. Executed [`simulations/simulate_suspicious_process.ps1`](../simulations/simulate_suspicious_process.ps1) on the Windows 11 workstation (`securitydesktop`) to generate fresh `certutil.exe` and `powershell.exe -EncodedCommand` telemetry:

```powershell
powershell -ExecutionPolicy Bypass -File .\simulate_suspicious_process.ps1
```

📸 **Evidence — Executing the Adversary Simulation to Trigger the Analytics Rules:**

![Simulate Suspicious Process Execution](../screenshots/case04_03_simulate_suspicious_process.png)

2. Opened the updated correlated incident (**ID 23**, updated `Last activity: Nov 4, 2026 1:00:36 PM`, `Evidence: 5` items) and inspected the **Incident Graph**:
   - Verified that the mapped entities—**Host (`securitydesktop`)**, **Account (`Mufti Security`)**, and **Process (`"powershell.exe" -ExecutionPolicy Bypass -File .\simulate_suspicious_process.ps1`)**—automatically linked as interactive graph nodes.

📸 **Evidence — Incident Graph with Mapped Host (`securitydesktop`), Account (`Mufti Security`) & Process Nodes:**

![Incident Graph Correlation](../screenshots/case04_03_investigation_graph.png)

---

## 📊 4. Key Findings & Operational Takeaways

- **Handling Ingestion Lag in Scheduled Rules:** Cloud telemetry pipelines occasionally experience 2–10 minute ingestion delays. By configuring a **2-hour lookback window** on a **1-hour execution schedule** combined with **Alert Grouping**, we ensure zero missed events while preventing duplicate incident creation.
- **When to Use NRT vs. Scheduled Rules:** NRT rules execute every 60 seconds and are ideal for high-signal, single-table atomic indicators (like `-EncodedCommand` on `powershell.exe` / `pwsh.exe`), whereas Scheduled rules should be used for multi-table `join` correlations and baseline anomaly aggregations.
