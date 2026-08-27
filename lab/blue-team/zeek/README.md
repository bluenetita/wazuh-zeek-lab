# Zeek Configuration

This directory contains the Zeek sensor configuration used to analyze traffic mirrored by Proxmox Open vSwitch.

## Contents

| Path | Purpose |
|---|---|
| `site/` | Local Zeek loading and custom scripts |
| `site/custom_scripts/reverse_shell/` | Suspicious download and reverse-shell lifecycle detection |
| `site/custom_scripts/data_exfiltration/` | Dynamic-baseline outbound-volume detection |
| `systemd/` | Service configuration |
| `logrotate/` | Rotation for custom logs |
| `netplan/` | Sanitized network configuration |
| `logs-samples/` | Safe sample schemas and publication guidance |

## Custom logs

```text
/var/log/zeek-custom/possible_malware.log
/var/log/zeek-custom/reverse_shell_live.log
/var/log/zeek-custom/reverse_shell_movement.log
/var/log/zeek-custom/reverse_shell_final.log
/var/log/zeek-custom/data_exfiltration.log
```

## Validation

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl deploy
sudo tail -f /var/log/zeek-custom/*.log
```

The detections are behavioral heuristics and must be correlated with endpoint telemetry before being treated as high-confidence findings.
