# Zeek Configuration

This directory contains the Zeek sensor configuration used to analyze traffic mirrored by Proxmox Open vSwitch.

## Contents

| Path | Purpose |
|---|---|
| `site/` | Local Zeek loading and site policy |
| `site/custom_scripts/reverse_shell/` | Suspicious download and reverse-shell lifecycle detection |
| `site/custom_scripts/data_exfiltration/` | Dynamic-baseline outbound-volume detection |
| `site/custom_scripts/scanning/` | ARP/TCP/UDP/address/ICMP scanning detection |
| `scripts/` | Local helper scripts for custom-log preparation |
| `systemd/` | Service configuration |
| `logrotate/` | Rotation for custom logs |
| `netplan/` | Sanitized network configuration |
| `logs-samples/` | Reduced sample schemas/evidence |

## Custom logs

```text
/var/log/zeek-custom/possible_malware.log
/var/log/zeek-custom/reverse_shell_live.log
/var/log/zeek-custom/reverse_shell_movement.log
/var/log/zeek-custom/reverse_shell_final.log
/var/log/zeek-custom/data_exfiltration.log
/var/log/zeek-custom/scanning.log
```

## Scanning schema

The current shared scanning schema uses `src_ip` as the scanner-source field. Historical test logs may contain `scanner_ip`; do not use those old records directly for current `same_field=src_ip` correlation tests without normalization.

## Validation

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl deploy
sudo tail -f /var/log/zeek-custom/*.log
```

These detections are behavioral heuristics. Treat them as observations and combine them with endpoint/context evidence before drawing a high-confidence conclusion.
