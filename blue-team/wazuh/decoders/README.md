# Wazuh Custom Decoders

This directory contains the active custom decoders used by the laboratory.

## Files

| File | Decoder | Purpose |
|---|---|---|
| `000_audit_saddr_decoder.xml` | `auditd_rs_connect_enriched` | Extracts process and destination fields from enriched Auditd `SYSCALL`/`SADDR` connection events |
| `001_apparmor_decoder.xml` | `apparmor_audit` family | Extracts AppArmor operation, profile, path, mask, process, capability, signal, network, D-Bus, and mount fields |

Zeek custom logs are JSON and use Wazuh's standard JSON decoder; the obsolete custom Zeek decoder files are not required.

## Validation

```bash
sudo /var/ossec/bin/wazuh-logtest
sudo /var/ossec/bin/wazuh-analysisd -t
```

Confirm the selected decoder and all fields required by downstream rules.
