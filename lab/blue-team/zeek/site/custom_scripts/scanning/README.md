# Zeek Scanning Detection

This package generates `/var/log/zeek-custom/scanning.log` and records several reconnaissance patterns using a shared JSON schema.

| Script | Event type | Current default threshold |
|---|---|---:|
| `host_scan.zeek` | `host_scan` | 20 unique ARP targets / 60 s |
| `port_scan.zeek` | `port_scan` | 100 unique TCP ports to one target / 60 s |
| `udp_scan.zeek` | `udp_port_scan` | 50 unique UDP ports to one target / 60 s |
| `address_scan.zeek` | `address_scan` | 2 unique hosts on one TCP port / 60 s |
| `icmp_scan.zeek` | `icmp_host_scan` | 2 unique ICMP targets / 60 s |

`logging.zeek` defines the shared log record and `__load__.zeek` loads all detector modules.

## Current schema

Common fields include:

```text
ts
event_type
src_ip
scanner_mac (optional)
target_ip (optional)
target_port (optional)
target_count (optional)
unique_ports (optional)
scan_window (optional)
protocol (optional)
note
```

The canonical source field is `src_ip`. Older rotated logs from earlier development iterations may use `scanner_ip`; that historical field should not be used in current correlation tests without normalization.

## Loading

`site/local.zeek` should include:

```zeek
@load custom_scripts/scanning
```

## Tuning

The `address_scan` and `icmp_host_scan` thresholds are intentionally low for validation. They can alert on legitimate multi-host traffic. Raise them and/or add justified allowlists before treating the configuration as production-like.

The TCP/UDP port-scan detectors operate on a short window and can miss slow scans spread over longer periods.

## Wazuh integration

- rules `100915-100919` classify the five event types;
- rules `120927-120934` correlate a later scanning event with an earlier reverse-shell correlation from the same `src_ip`.
