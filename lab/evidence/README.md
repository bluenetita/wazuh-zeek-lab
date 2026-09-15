# Sanitized Evidence

This directory contains reduced artifacts that demonstrate validated results without exposing complete logs, packet captures, payloads, credentials, signed webhooks, or personal data.

| Path | Purpose |
|---|---|
| `reverse-shell/` | Existing Zeek/Wazuh/correlation/containment evidence |
| `privilege-escalation/` | Existing Auditd/Wazuh privileged-execution evidence |
| `data-exfiltration/` | Existing baseline/threshold-exceedance evidence |
| `scanning/` | Reduced samples for the five current scanning event types |
| `apparmor/` | Reduced AppArmor denial evidence |

Evidence should include only the relevant fields, the expected decoder/rule, and an explanation of what the artifact demonstrates.

Do not commit Active Response archives, complete `alerts.json`, complete Auditd logs, rotated Zeek archives, PCAPs, transferred test data, or live RouterOS state.
