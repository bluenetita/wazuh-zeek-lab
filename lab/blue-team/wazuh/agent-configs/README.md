# Wazuh Agent Configurations

This directory contains sanitized agent configurations for the main telemetry sources.

| File | Host | Main sources |
|---|---|---|
| `zeek-agent-ossec.conf` | ZeekVM | Standard and custom Zeek logs |
| `client-linux-agent-ossec.conf` | ClientVM | Auditd, FIM, system logs, and endpoint telemetry |

## ZeekVM

The agent forwards Zeek JSON logs and files below `/var/log/zeek-custom/` to the manager.

## ClientVM

The agent monitors `/var/log/audit/audit.log` and File Integrity Monitoring paths such as `/home/client/Downloads`.

## Sanitization

Private laboratory IP addresses and reproducible paths may remain. Do not publish enrollment passwords, `client.keys`, API tokens, or credentials.

After changing monitored files, restart the corresponding agent and confirm ingestion in `/var/ossec/logs/ossec.log`.
