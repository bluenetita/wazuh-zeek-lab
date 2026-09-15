# Network Scanning Scenario

## Objective

Validate that mirrored reconnaissance traffic produces the expected Zeek scanning event and Wazuh base rule, and that scanning occurring after an earlier reverse-shell correlation can trigger a higher-confidence post-compromise rule.

## Detection coverage

| Activity pattern | Zeek event | Wazuh rule |
|---|---|---:|
| ARP host discovery | `host_scan` | `100915` |
| TCP port scan | `port_scan` | `100916` |
| UDP port scan | `udp_port_scan` | `100917` |
| Same TCP port across multiple hosts | `address_scan` | `100918` |
| ICMP host discovery | `icmp_host_scan` | `100919` |

Post-compromise correlation rules are `120927-120934` and require the scanner `src_ip` to match an earlier reverse-shell correlation within 900 seconds.

## Expected evidence

- one JSON event in `/var/log/zeek-custom/scanning.log`;
- the matching Wazuh base rule;
- for the correlated test, an earlier reverse-shell correlation rule followed by a scanning event from the same source address.

See `evidence/scanning/`.

## Tuning

The address-scan and ICMP thresholds are intentionally low in the current lab configuration. Treat them as validation thresholds and tune them before longer-running monitoring.

## Test-command note

Exact reconnaissance command lines are intentionally not included in the public update package. Keep authorized test commands in private lab notes.
