# Privilege-Escalation Monitoring

## Objective

Validate endpoint visibility for controlled privilege-related activity on ClientVM.

## Auditd keys and Wazuh rules

| Key | Wazuh rule | Meaning |
|---|---:|---|
| `suid_exec` | `100700` | Non-root execution with effective root privileges |
| `root_exec` | `100701` | Command from a root login session |
| `sudo_exec` | `100702` | `sudo` execution |
| `su_exec` | `100703` | `su` execution |
| `download_exec` | `100704` | Execution below the monitored Downloads path |

## Validation

Confirm the Auditd event contains the expected key, executable, UID/AUID/EUID, PID, PPID, and session information. Then verify the parent Wazuh Auditd rule and the custom rule.

## Interpretation

These alerts describe security-relevant actions but may be legitimate administration. Determine whether the binary, user, process ancestry, file origin, and surrounding activity support a malicious conclusion.

## Evidence

Store reduced examples under `evidence/privilege-escalation/`. Do not publish exploit code, SUID test binaries, credentials, or complete logs.
