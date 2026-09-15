# AppArmor

This directory contains the AppArmor profile used to confine the intentionally vulnerable inventory service running on ServerDB.

## Profile

```text
profiles/opt.inventario_service.inventario_c
```

Installed path:

```text
/etc/apparmor.d/opt.inventario_service.inventario_c
```

The supplied profile starts with `flags=(complain)` so required application behavior can be observed before enforcement. It grants the service its expected network and inventory-file access but does not grant general shell execution.

The commented `deny` lines are examples only and are not active policy.

## Load and mode validation

Reload after editing:

```bash
sudo apparmor_parser -r /etc/apparmor.d/opt.inventario_service.inventario_c
```

Check status:

```bash
sudo aa-status
```

For the isolated lab, compare complain mode and enforce mode only after verifying that required service operations are represented by the profile.

## Wazuh integration

AppArmor events are emitted through the Linux audit subsystem and collected by the ServerDB Wazuh Agent from `/var/log/audit/audit.log`.

Related files:

```text
blue-team/wazuh/decoders/001_apparmor_decoder.xml
blue-team/wazuh/rules/006_app_armor.xml
blue-team/wazuh/agent-configs/server-db-agent-ossec.conf
evidence/apparmor/apparmor-shell-denied-sanitized.log
```
