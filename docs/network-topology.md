# Network Topology

## Logical layout

```text
Simulated external network
        |
    AttackerVM
        |
     pfSense
        |
     RouterOS
        |
  Internal VLANs
        |
  +-----+-------------------+
  |                         |
ClientVM                 Other targets
  |
  +--> Wazuh Agent

Proxmox OVS mirror
        |
      VLAN 999
        |
      ZeekVM
        |
      Wazuh Agent
```

## Relevant laboratory addresses

| System | Address / role |
|---|---|
| RouterOS | `10.3.0.1` |
| ZeekVM management | `10.3.10.2/24` |
| Wazuh Manager | `10.3.10.3` |
| ClientVM | `10.3.20.2/24` |
| Client VLAN gateway | `10.3.20.1` |
| Mirror VLAN | `999` |

Addresses are private laboratory values and may be changed during deployment. Keep all configuration files and diagrams consistent when they change.

## Traffic visibility

Proxmox Open vSwitch mirrors selected VLAN traffic to VLAN 999. Zeek listens on the mirror interface and does not require an IP address on the capture interface.

## Quarantine path

The Wazuh Manager reaches RouterOS over SSH. When a response triggers, the ClientVM address is added to the RouterOS `Quarantine` address list and active tracked connections involving that address are removed.

## Routing considerations

The ClientVM uses an internal default route through the client VLAN gateway and may retain a secondary route for the quarantine design. Verify asymmetric routing, source addresses, and firewall behavior after every network change.
