# ZeekVM Network Configuration

This directory contains a sanitized Netplan configuration for the Zeek sensor.

The VM uses:

- a management interface with an IP address and default route;
- a dedicated mirror/trunk interface for passive capture;
- VLAN 999 as the OVS mirror destination.

The capture interface should not use a default route and normally does not require an IP address.

Validate changes with:

```bash
sudo netplan generate
sudo netplan try
ip -br addr
ip route
```

Interface names may differ between deployments and must be reviewed before applying the file.
