# Wazuh Agent Configurations

This directory contains sanitized configurations for the principal telemetry sources.

| File | Host | Main sources |
|---|---|---|
| `zeek-agent-ossec.conf` | ZeekVM | Standard Zeek JSON, reverse shell, exfiltration, scanning, SSH, MITM, and ICMP Flood |
| `client-linux-agent-ossec.conf` | ClientVM | Auditd, FIM, system logs, and endpoint telemetry |
| `server-db-agent-ossec.conf` | ServerDB | Linux Audit/AppArmor events and system logs |

## ZeekVM

The agent collects Zeek JSON logs and designated custom files under `/var/log/zeek-custom/`, including `scanning.log`, `ssh_bruteforce.log`, `mitm_arp.log`, `mitm_dhcp.log`, `mitm_dns.log`, and `icmp_flood.log`.

For ICMP Flood, the agent reads the **exact** `/var/log/zeek-custom/icmp_flood.log` path as JSON; an overlapping `/var/log/zeek-custom/*.log` wildcard is not needed. The scenario uses `<only-future-events>yes</only-future-events>` to avoid replaying historical alerts after the agent is restarted. This is a sanitized **reference configuration**, not an automatic deployment. The Manager rule `100940` is location-sensitive, so retain the `.log` path in events and `wazuh-logtest -l` checks. Do not add source-IP quarantine from ICMP evidence alone.

The dedicated log integration index is in [`../integrations/zeek-custom-logs.md`](../integrations/zeek-custom-logs.md).

## ClientVM

The agent monitors the existing Auditd and FIM sources used by reverse-shell/privilege validation.

## ServerDB

The ServerDB agent collects `/var/log/audit/audit.log`. AppArmor decisions written through the Linux audit subsystem are therefore forwarded to the Wazuh Manager and can be decoded by `001_apparmor_decoder.xml`.

## Sanitization

Private laboratory IP addresses and reproducible paths may remain. Do not publish enrollment passwords, `client.keys`, API tokens, private keys, credentials, or signed webhook URLs.

After changing monitored files, restart the corresponding agent and confirm ingestion in `/var/ossec/logs/ossec.log`.
