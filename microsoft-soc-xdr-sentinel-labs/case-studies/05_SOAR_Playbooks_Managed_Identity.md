# Case Study 05: Zero-Trust SOAR Engineering with Azure Logic Apps & Managed Identity

| Metadata | Details |
| :--- | :--- |
| **Role Focus** | SOAR Engineer / Security Automation Analyst |
| **Core Capabilities** | Sentinel Automation Rules, Azure Logic Apps Playbooks, System-Assigned Managed Identity, Azure RBAC (`Microsoft Sentinel Responder`) |
| **Platforms Used** | Microsoft Sentinel, Azure Logic Apps, Microsoft Entra ID IAM |

---

## 🎯 1. Objective & Problem Statement

When a High-Severity incident triggers in a 24/7 SOC, analysts spend valuable minutes performing repetitive administrative tasks: changing incident status to `Active`, assigning an owner, applying triage tags, and posting initial investigation checklists. Furthermore, legacy SOAR playbooks frequently authenticate using service account passwords or expiring client secrets—creating a credential-theft risk inside the automation tier itself.

**SOAR Engineering Objective:**
1. Deploy an **Azure Logic App Playbook** (`Playbook-Incident-AutoTriage`) to automate incident enrichment and structured triage documentation.
2. Eliminate hardcoded API keys and passwords by configuring a **System-Assigned Managed Identity** and assigning the least-privilege **Microsoft Sentinel Responder** role via Azure RBAC.
3. Build a **Microsoft Sentinel Automation Rule** (`Auto-Triage High Severity Incidents`) that intercepts newly created `High` severity incidents, assigns ownership, applies standardized tags (`AutoTriaged`), and triggers the Logic App workflow.
4. Validate end-to-end execution via the incident comment timeline and Logic Apps run history (`HTTP 200 Succeeded`).

---

## 🏗️ 2. Zero-Trust SOAR Architecture

```mermaid
flowchart LR
    Inc["New High-Severity<br/>Sentinel Incident"] --> Auto["Sentinel Automation Rule<br/>(Auto-Triage High Severity Incidents)"]
    Auto -->|1. Native Actions| Native["- Set Status: Active<br/>- Assign Owner<br/>- Add Tag: AutoTriaged"]
    Auto -->|2. Invoke Playbook| LA["Azure Logic App<br/>(Playbook-Incident-AutoTriage)"]
    LA <-->|Zero-Trust Auth:<br/>System-Assigned Managed Identity<br/>(RBAC: Sentinel Responder)| Entra["Microsoft Entra ID<br/>& Azure IAM"]
    LA -->|3. API Callback| Comment["Posts Structured Markdown<br/>Triage Checklist to Incident"]
```

---

## 🛠️ 3. Implementation & Engineering Procedure

### Phase 1: Provisioning the Azure Logic App & System-Assigned Managed Identity
1. Created Consumption-tier Azure Logic App **`Playbook-Incident-AutoTriage`** inside resource group `rg-sentinel-soc`.
2. Navigated to **Settings** > **Identity** > **System assigned**, toggled **Status** to **On**, and registered the Logic App as a managed enterprise service principal in Microsoft Entra ID.
3. Navigated to the Sentinel Resource Group (`rg-sentinel-soc`) > **Access control (IAM)** > **Add role assignment**:
   - **Role:** `Microsoft Sentinel Responder`
   - **Assign access to:** `Managed identity` → `Playbook-Incident-AutoTriage`

📸 **Evidence — Managed Identity & `Microsoft Sentinel Responder` RBAC Assignment:**
> *Place screenshot at:* `../screenshots/case05_01_managed_identity_rbac.png`  
> ![Managed Identity RBAC Assignment](../screenshots/case05_01_managed_identity_rbac.png)

---

### Phase 2: Authoring the Logic App Workflow
In the **Logic App Designer**, I built the automated workflow:
1. **Trigger:** `Microsoft Sentinel incident` *(When a response to an Microsoft Sentinel Alert/Incident is triggered)* authenticated via **`Logic App Managed Identity (System-assigned)`**.
2. **Action:** `Add comment to incident (V3)` dynamically bound to the incoming `Incident ARM ID`, injecting the standardized SOC triage runbook directly into the ticket timeline:

```markdown
### 🤖 Automated SOC Triage - Initial Analysis
- **Triage Status:** Automated playbook triggered via System-Assigned Managed Identity.
- **Verification Checklist:**
  1. [ ] Check host network isolation status in Defender XDR.
  2. [ ] Review user MFA and recent SigninLogs in Microsoft Entra ID.
  3. [ ] Verify related alerts in Microsoft Defender XDR Attack Story.
```

📸 **Evidence — Logic App Designer Workflow:**
> *Place screenshot at:* `../screenshots/case05_02_logic_app_designer.png`  
> ![Logic App Designer Workflow](../screenshots/case05_02_logic_app_designer.png)

---

### Phase 3: Configuring the Sentinel Automation Rule
In **Microsoft Sentinel** > **Configuration** > **Automation**, I created the orchestration rule:
- **Name:** `Auto-Triage High Severity Incidents`
- **Trigger:** `When incident is created`
- **Condition:** `If Severity Equals High`
- **Chained Actions:**
  1. **Assign owner:** Assigned to the on-duty SOC Analyst account.
  2. **Add tags:** Added tag `AutoTriaged`.
  3. **Run playbook:** Invoked `Playbook-Incident-AutoTriage`.

📸 **Evidence — Sentinel Automation Rule Configuration:**
> *Place screenshot at:* `../screenshots/case05_03_automation_rule.png`  
> ![Sentinel Automation Rule](../screenshots/case05_03_automation_rule.png)

---

### Phase 4: End-to-End Execution & Audit Verification
1. Triggered a High-Severity incident in Microsoft Sentinel.
2. Inspected the incident pane and verified that:
   - The `AutoTriaged` tag and owner were applied immediately upon creation.
   - The Logic App posted the Markdown verification checklist into the **Comments** activity feed within seconds.
3. Verified the execution trace in **Logic App > Runs history**, confirming `Succeeded` status (`HTTP 200`) across both trigger and response steps.

📸 **Evidence — Automated Incident Comment & Logic App Run History:**
> *Place screenshot at:* `../screenshots/case05_04_incident_comment_and_run_history.png`  
> ![Automated Comment & Logic App Run History](../screenshots/case05_04_incident_comment_and_run_history.png)

---

## 📊 4. Key Findings & Operational Takeaways

- **Two-Tier SOAR Architecture:** Using **Sentinel Automation Rules** for lightweight in-SIEM triage (tagging, status changes, owner assignment) before invoking **Azure Logic Apps** reduces Logic App consumption executions and centralizes conditional logic in one rule engine.
- **Zero-Trust Secretless Automation:** Authenticating Logic Apps via **System-Assigned Managed Identity** with scoped Azure RBAC (`Microsoft Sentinel Responder`) removes the risk of leaked API keys or broken playbooks due to expired service principal secrets.

