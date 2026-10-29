# Wazuh Agent Configurations

This directory contains sanitized configurations for the principal telemetry sources.

| File | Host | Main sources |
|---|---|---|
| `zeek-agent-ossec.conf` | ZeekVM | Standard Zeek logs plus custom reverse-shell, exfiltration, and scanning logs |
| `client-linux-agent-ossec.conf` | ClientVM | Auditd, FIM, system logs, and endpoint telemetry |
| `server-db-agent-ossec.conf` | ServerDB | Linux Audit/AppArmor events and system logs |

## ZeekVM

The agent collects Zeek JSON logs and custom files under `/var/log/zeek-custom/`, including `/var/log/zeek-custom/scanning.log` and the separate ICMP Echo Flood detector stream `/var/log/zeek-custom/icmp_flood.log`.

### Data Exfiltration collector on ZeekVM

Exactly one JSON `<localfile>` monitors `/var/log/zeek-custom/data_exfiltration.log`, with `only-future-events=yes` and PCRE2 `restrict` selectors for `exfil_adaptive_decision` and `exfil_slow_window_decision` candidates plus eligible Slow continuation states. Diagnostic windows stay in the local Zeek log and are not all forwarded as alerts. This is the **consolidated** stream; no separate `data_exfiltration_shadow.log` collector is active.

## ClientVM

The agent monitors the existing Auditd and FIM sources used by reverse-shell/privilege validation.

## ServerDB

The ServerDB agent collects `/var/log/audit/audit.log`. AppArmor decisions written through the Linux audit subsystem are therefore forwarded to the Wazuh Manager and can be decoded by `001_apparmor_decoder.xml`.

## Sanitization

Private laboratory IP addresses and reproducible paths may remain. Do not publish enrollment passwords, `client.keys`, API tokens, private keys, credentials, or signed webhook URLs.

After changing monitored files, restart the corresponding agent and confirm ingestion in `/var/ossec/logs/ossec.log`.
