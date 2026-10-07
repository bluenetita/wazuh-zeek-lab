# Scenarios

This directory contains the scenarios that are actually documented in the cyber range. Each scenario links its objective, involved systems, detection logic, and observed results. Reusable offensive payloads, exploits, and similar material are not published.

## Scenarios

| Scenario | Directory | Status | Main components |
|---|---|---|---|
| Reverse Shell | `reverse-shell/` | Validated | Zeek, Auditd, Wazuh |
| Privilege Escalation | `privilege-escalation/` | Validated | Auditd/Wazuh |
| Network Scanning | `network-scanning/` | Validated | Zeek + Wazuh |
| AppArmor Mitigation | `apparmor-mitigation/` | Validated | ServerDB + AppArmor + Wazuh |
| Active Response | `active-response/` | Validated | Wazuh + RouterOS |
| SSH Brute Force | `ssh-bruteforce/` | Validated | Zeek + sshd + Wazuh |

## Observability flow

```text
Network traffic -> Zeek ------------+
                                      |
Host events -----> Wazuh Agent ----> Wazuh Manager -> decoders/rules -> alerts
                                      |
                                      +-> Active Response (if enabled)
```

## Validation principle

Where available, positive tests are accompanied by negative controls or OFF/ON comparisons. Reduced evidence is stored under [`../evidence/`](../evidence/README.md).

For SSH, validation uses two sources and two victims to verify that correlation does not mix sessions from different pairs. For AppArmor, the same operation is compared between complain and enforce modes. For RouterOS, behavior is compared with Active Response disabled and enabled.
