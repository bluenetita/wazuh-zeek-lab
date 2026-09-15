# Controlled Inventory Service

This directory contains the source and deployment files for an intentionally unsafe inventory service used only inside the isolated laboratory to validate application confinement and monitoring.

## Files

```text
src/inventario.c
products/lista.txt
systemd/inventario-terminale.service
```

The compiled `inventario_c` binary is intentionally not versioned.

## Defensive purpose

The service deliberately performs unsafe shell-command construction from untrusted input so the laboratory can compare:

- visibility when AppArmor is in complain mode;
- prevention when the AppArmor profile is in enforce mode;
- Audit/AppArmor telemetry received by Wazuh;
- Wazuh rule classification of denied execution and related policy violations.

This repository documentation intentionally does not publish an exploitation payload or credential-guessing workflow.

## Deployment boundary

Use this service only on an isolated, authorized test network. Do not expose it to untrusted or production networks.
