# 📸 Screenshot Checklist for `microsoft-soc-xdr-sentinel-labs`

As you execute each lab, save your screenshots into this `screenshots/` folder using the exact filenames below. Every Case Study markdown file (`case-studies/01_*.md` through `07_*.md`) is already pre-linked to these exact filenames—so the moment you drop an image here, it will automatically render on GitHub!

| Case Study | Filename to Save in `screenshots/` | What to Capture |
| :---: | :--- | :--- |
| **Case 01** | `case01_01_device_onboarded.png` | Defender XDR > Assets > Devices showing your Windows 11 PC as `Onboarded` & `Active` |
| **Case 01** | `case01_02_intune_asr_policy.png` | Intune Admin Center > Endpoint Security > Attack Surface Reduction policy rules configured |
| **Case 01** | `case01_03_tamper_protection.png` | Defender XDR > Settings > Endpoints > Advanced features showing `Tamper protection: On` |
| **Case 01** | `case01_04_powershell_asr_verification.png` | Terminal output of running `.\simulations\test_asr_rules.ps1` in PowerShell |
| **Case 01** | `case01_05_kql_asr_hunting.png` | Defender XDR > Advanced Hunting showing the `DeviceEvents` ASR KQL query results |
| **Case 02** | `case02_01_simulation_execution.png` | PowerShell terminal running `.\simulations\simulate_suspicious_process.ps1` |
| **Case 02** | `case02_02_attack_story_graph.png` | Defender XDR Incident page showing the Attack Story process tree (`certutil` / `powershell`) |
| **Case 02** | `case02_03_live_response_cli.png` | Defender XDR Live Response console running `processes` and `fileinfo` |
| **Case 02** | `case02_04_selective_isolation.png` | Defender XDR Isolate Device flyout showing Full vs. Selective Isolation options |
| **Case 02** | `case02_05_kql_certutil_telemetry.png` | Advanced Hunting results for `DeviceProcessEvents` showing `certutil.exe -urlcache -split` |
| **Case 03** | `case03_01_sentinel_workspace.png` | Microsoft Sentinel Overview page on `law-sentinel-soc-prod` |
| **Case 03** | `case03_02_xdr_connector_tables.png` | Sentinel > Data connectors > Microsoft Defender XDR showing Incidents & Raw Tables checked |
| **Case 03** | `case03_03_entra_id_connector.png` | Sentinel > Data connectors > Microsoft Entra ID showing `SigninLogs` and `AuditLogs` connected |
| **Case 03** | `case03_04_kql_ingestion_verification.png` | Sentinel > Logs running `DeviceProcessEvents`, `SecurityIncident`, or `SentinelHealth` KQL |
| **Case 04** | `case04_01_scheduled_rule_logic.png` | Sentinel Analytics Rule wizard showing the `certutil.exe` KQL query & Host/Account Entity Mapping |
| **Case 04** | `case04_02_nrt_rule_config.png` | Sentinel NRT Analytics Rule wizard showing the Encoded PowerShell query |
| **Case 04** | `case04_03_investigation_graph.png` | Sentinel Investigation Graph showing the Alert node linked to your Windows 11 Host and Account |
| **Case 05** | `case05_01_managed_identity_rbac.png` | Logic App System-Assigned Identity = `On` and IAM Role Assignment (`Microsoft Sentinel Responder`) |
| **Case 05** | `case05_02_logic_app_designer.png` | Logic App Designer showing `Microsoft Sentinel incident` trigger + `Add comment to incident (V3)` |
| **Case 05** | `case05_03_automation_rule.png` | Sentinel Automation Rule (`Auto-Triage High Severity Incidents`) showing conditions and actions |
| **Case 05** | `case05_04_incident_comment_and_run_history.png` | Sentinel Incident showing the automated Markdown comment + `AutoTriaged` tag |
| **Case 06** | `case06_01_kql_hunting_results.png` | KQL Hunting query results (LOLBAS LFO count, Base64 Regex extraction, or `schtasks.exe`) |
| **Case 06** | `case06_02_hunting_bookmark_promotion.png` | Sentinel Hunting Bookmarks pane showing your bookmarked event and `Create Incident` |
| **Case 06** | `case06_03_sentinel_livestream.png` | Sentinel Livestream session monitoring live events |
| **Case 07** | `case07_01_purview_sensitivity_label.png` | Microsoft Purview > Information Protection > Labels showing `Confidential - Financial Data` |
| **Case 07** | `case07_02_entra_conditional_access_mdca.png` | Entra Conditional Access policy showing Session > `Use Conditional Access App Control` |
| **Case 07** | `case07_03_mdca_session_policy.png` | Defender XDR > Cloud apps > Policies showing the Session Policy blocking Confidential downloads |
| **Case 07** | `case07_04_mcas_download_blocked.png` | Browser showing `*.mcas.ms` reverse proxy URL and the real-time download blocked notification |

