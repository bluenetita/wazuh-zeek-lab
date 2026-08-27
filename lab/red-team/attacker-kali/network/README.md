# Kali Network Configuration

This directory contains the sanitized network configuration for AttackerVM.

Document interface name, private address, prefix, gateway, DNS behavior, Proxmox bridge, and routing toward the internal target. Keep the filename references consistent with the actual configuration stored in this directory.

Validation:

```bash
ip -br addr
ip route
traceroute <TARGET_IP>
```

Do not publish VPN credentials, private keys, or unrelated routes.
