# Network Topology
## Logical roles

The lab is segmented so that monitoring and controlled attack traffic can be observed across multiple internal networks.
| System | Current lab role | Example/current address used by the project |
|---|---|---|
| ZeekVM | Passive sensor and Wazuh log source | `10.3.10.2` |
| Wazuh Manager | SIEM/correlation manager | `10.3.10.3` |
| ClientVM | Main Linux endpoint | `10.3.20.2` |
| Client-Linux2 | Additional Linux endpoint; protected client in the MITM validation | `10.3.20.4` |
| ServerDB | Server target for AppArmor/inventory-service tests | `10.3.30.3` |
| AttackerVM | Authorized external/lab test source | `10.2.0.0/24` lab segment |
Before publishing or reproducing the environment, verify these values against the current Proxmox, RouterOS/pfSense, Netplan, and Wazuh agent configurations.
## VLAN model

The project uses internal VLANs for monitored workloads and VLAN 999 as the mirror destination toward ZeekVM. Proxmox Open vSwitch mirrors traffic from the monitored VLANs to the Zeek capture path.

```text
VLAN 10 -----\
VLAN 20 ------+--> OVS mirror --> VLAN 999 --> ZeekVM capture interface
VLAN 30 -----/
```
## Visibility assumptions

- Scanning detection works only when the relevant ARP/IP traffic is visible to the Zeek sensor.
- ARP host discovery requires link-layer traffic from the scanned segment to reach the sensor.
- MITM ARP-binding detection has the same layer-2 visibility requirement; routed traffic alone is not sufficient.
- Correlation depends on consistent source-address representation between Zeek and Wazuh events.
- RouterOS quarantine depends on the victim address being routable through the device and matching the firewall/address-list policy.

## MITM scenario role note

During the controlled MITM campaign, `10.3.20.2` is temporarily used as the authorized test source and `10.3.20.4` as the protected client. Those are scenario-specific roles and do not redefine the hosts' roles in the SSH validation topology. The Zeek ARP baseline also protects the VLAN 20 gateway at `10.3.20.1`.

## ServerDB placement

ServerDB is documented as a separate internal server role. Its Wazuh Agent forwards AppArmor/Audit events to the manager. Network activity involving ServerDB is observed by Zeek when it crosses the mirrored VLAN path.
## Change-control note

Whenever an IP, VLAN ID, bridge, interface, gateway, or VM role changes, update all dependent documentation and configuration references. Do not update only this file; Wazuh rules, agent configurations, scenario notes, and evidence descriptions may also depend on the old value.
