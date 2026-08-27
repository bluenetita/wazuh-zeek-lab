# Open vSwitch Traffic Mirroring

The laboratory uses an OVS mirror to copy selected VLAN traffic to VLAN 999, where ZeekVM captures it passively.

The mirror should select the monitored VLANs and use a dedicated output VLAN/interface. Confirm packet visibility with `tcpdump` on ZeekVM after every bridge or VLAN change.

The deployment script is stored under `proxmox/ovs/`. Make the script idempotent and verify that only one intended mirror exists.
