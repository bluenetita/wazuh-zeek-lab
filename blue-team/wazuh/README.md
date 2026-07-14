# Wazuh Configuration

This directory contains the sanitized Wazuh components used by the laboratory.

## Structure

| Path | Purpose |
|---|---|
| `agent-configs/` | ZeekVM and ClientVM agent configuration |
| `decoders/` | Auditd SADDR and AppArmor decoders |
| `rules/` | Zeek, Auditd, correlation, privilege, and exfiltration rules |
| `manager/` | Sanitized Wazuh Manager `ossec.conf` |
| `active-response/` | Endpoint evidence collection and RouterOS quarantine |
| `integrations/` | Notes for custom log or notification integrations |
| `log-samples/` | Reduced examples for testing and documentation |

## Data sources

- standard and custom Zeek JSON logs;
- Auditd events from ClientVM;
- AppArmor audit events;
- Wazuh FIM and system events;
- Active Response logs.

## Correlation strategy

Low-level rules identify observations. Rules in `004_zeek_auditd_correlation.xml` combine network and endpoint evidence and increase severity across reverse-shell start, movement, and final stages.

## Sensitive material

Do not commit `client.keys`, `authd.pass`, private certificates, private SSH keys, live webhooks, RouterOS credentials, or complete alert archives.
