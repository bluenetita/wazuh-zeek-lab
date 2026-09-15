# Wazuh Custom Rules

This directory contains the active laboratory ruleset and the new scanning/AppArmor additions.

## Files and rule ranges

| File | Rule IDs | Purpose |
|---|---|---|
| `001_zeek_rules.xml` | `100900-100907` | Base JSON, DNS, rejected connections, and TLS conditions |
| `002_zeek_rules_custom.xml` | `100909-100919` | Reverse shell, data exfiltration, and Zeek scanning base rules |
| `003_auditd_rev_shell.xml` | `110900` | Successful endpoint outbound connection from enriched Auditd data |
| `004_zeek_auditd_correlation.xml` | `120900-120926` | Reverse-shell cross-source correlation chains |
| `005_zeek_scanning_correlation.xml` | `120927-120934` | Scanning after an earlier reverse-shell correlation |
| `006_app_armor.xml` | `130900-130983` | AppArmor denial classification and repeated-activity correlation |
| `1004_auditd_rules.xml` | `100700-100704` | SUID, root, `sudo`, `su`, and downloads-directory execution |

## Scanning base rules

| Rule | Level | Event |
|---:|---:|---|
| `100915` | 6 | `host_scan` |
| `100916` | 7 | `port_scan` |
| `100917` | 7 | `udp_port_scan` |
| `100918` | 7 | `address_scan` |
| `100919` | 6 | `icmp_host_scan` |

All scanning rules add group `zeek_scanning`, which is consumed by the correlation rules.

## Reverse-shell to scanning correlation

Rules `120927-120934` follow previously matched reverse-shell correlation rules and require the later scanning event to have the same `src_ip` inside a 900-second window.

| New rule | Earlier reverse-shell rule |
|---:|---:|
| `120927` | `120901` |
| `120928` | `120904` |
| `120929` | `120907` |
| `120930` | `120910` |
| `120931` | `120914` |
| `120932` | `120917` |
| `120933` | `120921` |
| `120934` | `120924` |

## AppArmor rules

The AppArmor rules start with generic denial rule `130900` and specialize file read/write denial, executable denial, shell/interpreter/tool execution, Linux capabilities, network operations, ptrace, mount, signal, D-Bus, sensitive files, persistence paths, and repeated-denial behavior.

High-severity examples include:

- `130920`: blocked shell execution;
- `130931`: high-risk Linux capability denial;
- `130963`: persistence-related modification denial;
- `130964`: security-monitoring modification denial;
- `130981`: repeated executable-launch denials.

## Validation

```bash
sudo /var/ossec/bin/wazuh-logtest
sudo /var/ossec/bin/wazuh-analysisd -t
```

Correlation tests require the complete event sequence, not a single isolated log line. Keep historical `scanner_ip` samples separate from the current `src_ip` schema.
