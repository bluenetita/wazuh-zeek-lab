# VLAN Design

The laboratory separates systems by role and mirrors selected traffic to a dedicated sensor VLAN.

| VLAN | Purpose |
|---:|---|
| 10 | Management / blue-team services |
| 20 | Client endpoints |
| 30 | Server segment |
| 999 | OVS mirror destination for Zeek |

VLAN IDs and bridge mappings must remain consistent across Proxmox, pfSense, RouterOS, VM interfaces, and diagrams.

VLAN 999 is intended for passive monitoring and should not become a normal routed user network.
