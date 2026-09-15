# Infrastructure Systems

This directory documents the monitored systems and controlled laboratory targets.

| Path | Role |
|---|---|
| `client-linux/` | Main Linux endpoint for Auditd, FIM, reverse shell, and privilege-escalation validation |
| `client-windows/` | Additional Windows endpoint |
| `server-db/` | Server role used for AppArmor and controlled inventory-service validation |
| `victim-server/` | Additional controlled target |

ServerDB now has explicit endpoint telemetry through a Wazuh Agent and AppArmor/Audit events. Keep runtime credentials and compiled binaries out of this directory.
