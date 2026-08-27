# Wazuh Custom Rules

This directory contains the active laboratory ruleset.

## Files and rule ranges

| File | Rule IDs | Purpose |
|---|---|---|
| `001_zeek_rules.xml` | `100900–100907` | Base JSON, DNS, rejected connections, scanning, and TLS certificate conditions |
| `002_zeek_rules_custom.xml` | `100909–100914` | Possible malware, reverse-shell lifecycle, baseline completion, and possible data exfiltration |
| `003_auditd_rev_shell.xml` | `110900` | Successful endpoint outbound connection from enriched Auditd data |
| `004_zeek_auditd_correlation.xml` | `120900–120926` | Cross-source reverse-shell correlation chains |
| `1004_auditd_rules.xml` | `100700–100704` | SUID, root, `sudo`, `su`, and downloads-directory execution |

## Correlation chains

The correlation file supports:

- malware download and later connection to a different destination;
- reverse shell without observed download evidence;
- same destination with different filename;
- same destination and same filename;
- alternative event-arrival orders;
- start, movement, and final lifecycle severity progression.

`global_frequency` is used where events originate from ZeekVM and ClientVM.

## Data exfiltration

Rule `100913` records baseline completion. Rule `100914` reports a possible exfiltration event when the custom Zeek threshold is exceeded.

## Privilege rules

Rules `100700–100704` depend on Wazuh's standard Auditd command rule and distinguish events through `audit.key`.

Review the MITRE mapping for `download_exec`: execution from a directory alone does not prove use of valid accounts or a malicious file.

## Validation

```bash
sudo /var/ossec/bin/wazuh-logtest
sudo /var/ossec/bin/wazuh-analysisd -t
```

Correlation tests require complete event sequences, not a single log line.
