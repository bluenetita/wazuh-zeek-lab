# Wazuh Custom Decoders

This directory contains the active custom decoders used by the laboratory.

| File | Decoder | Purpose |
|---|---|---|
| `000_audit_saddr_decoder.xml` | `auditd_rs_connect_enriched` | Extracts process/destination fields from enriched Auditd connection events |
| `001_apparmor_decoder.xml` | `apparmor_audit` family | Extracts AppArmor decision, operation, profile, path, process, masks, capability, signal, network, D-Bus, and mount fields |

Zeek custom logs are JSON and use Wazuh's standard JSON decoding path; obsolete custom Zeek decoder files are not required.

## AppArmor data flow

```text
ServerDB AppArmor decision
        |
        v
Linux Audit / /var/log/audit/audit.log
        |
        v
Wazuh Agent on ServerDB
        |
        v
apparmor_audit decoder family
        |
        v
rules 130900-130983
```

Important extracted fields include:

```text
apparmor.audit_type
apparmor.audit_id
apparmor.event
apparmor.operation
apparmor.object_class
apparmor.profile
apparmor.name
apparmor.name2
apparmor.pid
apparmor.command
apparmor.requested
apparmor.denied
apparmor.fsuid
apparmor.ouid
apparmor.capability
apparmor.capability_name
apparmor.network_family
apparmor.socket_type
apparmor.protocol
```

## Validation

```bash
sudo /var/ossec/bin/wazuh-logtest
sudo /var/ossec/bin/wazuh-analysisd -t
```

Confirm the selected decoder and every field required by the downstream rule being tested.
