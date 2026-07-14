# Virtual Machine Inventory

| VM | Role |
|---|---|
| Wazuh Manager | Central analysis, correlation, and Active Response |
| ZeekVM | Passive network sensor |
| ClientVM | Primary Linux target and endpoint telemetry source |
| AttackerVM | Controlled Kali Linux test source |
| pfSense | External/internal firewall |
| RouterOS | Internal routing and quarantine enforcement |
| Client Windows | Additional endpoint |
| Server DB / victim server | Additional target roles |

Record VM IDs, CPU/RAM, disks, interfaces, bridges, and VLAN tags in a sanitized form. Do not include passwords or disk images.
