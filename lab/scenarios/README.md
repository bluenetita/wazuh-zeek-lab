# Security Scenarios

This directory contains controlled validation scenarios for the monitoring and response architecture.

| Scenario | Main telemetry | Validation goal |
|---|---|---|
| `reverse-shell/` | Zeek, Auditd, Wazuh correlation, Active Response | Correlate network/endpoint evidence and test containment |
| `privilege-escalation/` | Auditd keys, Wazuh privilege rules, FIM/system context | Detect privileged/post-exploitation execution |
| `data-exfiltration/` | Zeek baseline/custom JSON and Wazuh rules | Detect an authorized volume anomaly |
| `network-scanning/` | Zeek scanning JSON and Wazuh `100915-100919` | Detect several scan patterns |
| `apparmor-mitigation/` | AppArmor Audit events and Wazuh `1309xx` rules | Compare complain/enforce behavior |
| `command-injection/` | ServerDB AppArmor/Audit effects | Demonstrate defensive visibility around the intentionally unsafe service |
| `full-attack-chain/` | Multiple sources | Document the end-to-end defensive coverage and gaps |
| `pivoting-ssh-bruteforce/` | Current coverage gap | Document later-stage activity without claiming a dedicated custom detector |

Each scenario should define objective, systems, prerequisites, safe descriptive actions, expected telemetry, decoder/rule IDs, interpretation, cleanup, limitations, and sanitized evidence.

## Safety

Do not publish weaponized payloads, credentials, private keys, raw logs, full PCAPs, malicious binaries, signed webhooks, or reusable offensive command sequences. Keep operational attack commands in private lab notes when necessary for authorized testing.
