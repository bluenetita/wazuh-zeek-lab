# Sanitized Evidence

This directory contains reduced artifacts that demonstrate validated results without exposing complete logs, packet captures, payloads, credentials, or personal data.

## Scenario directories

| Path | Purpose |
|---|---|
| [`reverse-shell/`](reverse-shell/) | Zeek, Wazuh, correlation, and containment evidence |
| [`privilege-escalation/`](privilege-escalation/) | Auditd and Wazuh privileged-execution evidence |
| [`data-exfiltration/`](data-exfiltration/) | Baseline, threshold-exceedance, and Wazuh alert evidence |

Evidence should include:

- source and scenario;
- timestamp placeholder or controlled test timestamp;
- relevant fields only;
- expected rule or decoder;
- explanation of what the artifact proves;
- reference to the scenario documentation.

Do not commit Active Response archives, complete `alerts.json`, complete Auditd logs, PCAPs, transferred test data, or live RouterOS state.
