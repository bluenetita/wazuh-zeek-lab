# Proxmox Network Bridges

Document each bridge with type, attached physical interface, VLAN awareness, connected VM interfaces, and purpose.

The OVS bridge used for monitored VLANs must preserve tags and provide a mirror destination toward VLAN 999/ZeekVM.

Validate with:

```bash
ip -br link
ovs-vsctl show
```
