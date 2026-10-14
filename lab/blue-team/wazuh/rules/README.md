# Wazuh Custom Rules

This directory contains the custom laboratory ruleset for network telemetry, endpoint telemetry, correlation, and scenario-specific detections. Rule IDs below describe the checked-in files; they do not enable any Active Response by themselves.

## Files and rule ranges

| File | Rule IDs | Purpose |
|---|---|---|
| `001_zeek_rules.xml` | `100900-100907` | Base JSON, DNS, rejected connections, and TLS conditions |
| `002_zeek_rules_custom.xml` | `100909-100919` | Reverse shell, data exfiltration, and Zeek scanning base rules |
| `003_auditd_rev_shell.xml` | `110900` | Successful endpoint outbound connection from enriched Auditd data |
| `004_zeek_auditd_correlation.xml` | `120900-120926` | Reverse-shell cross-source correlation chains |
| `005_zeek_scanning_correlation.xml` | `120927-120934` | Scanning after an earlier reverse-shell correlation |
| `006_app_armor.xml` | `130900-130983` | AppArmor denial classification and repeated-activity correlation |
| `1004_auditd_rules.xml` | `100700-100704` | SUID, root, `sudo`, `su`, and downloads-directory execution |
| `007_mitm_rules.xml` | `100930-100932` | ARP mismatch, unexpected DHCP responder, protected DNS answers |
| `008_zeek_icmp_flood_rules.xml` | `100940` | Destination-focused ICMP Echo Flood anomaly |
| `9999_ssh_bruteforce_correlation.xml` | `100920-100921`, `120935-120941` and other SSH rules | SSH candidate confirmation, pair-based correlations and fan-in/fan-out |

## Scanning base rules

| Rule | Level | Event |
|---:|---:|---|
| `100915` | 6 | `host_scan` |
| `100916` | 7 | `port_scan` |
| `100917` | 7 | `udp_port_scan` |
| `100918` | 7 | `address_scan` |
| `100919` | 6 | `icmp_host_scan` |

All scanning rules add group `zeek_scanning`, which is consumed by the correlation rules.

## ICMP Echo Flood vs ICMP reconnaissance

Rule `100919` is `icmp_host_scan`: a host probing multiple destinations. It is **not** the ICMP Echo Flood detector. Rule `100940` belongs to `008_zeek_icmp_flood_rules.xml` and triggers on a Zeek JSON event with `event_type=icmp_flood_suspected` and a log location matching `icmp_flood.log`. It is level 8 and mapped to ATT&CK `T1498.001`. The event counts mirrored **observations**, not de-duplicated requests; `dest_ip` identifies the monitored victim and `source_attribution=unverified` expressly avoids claiming attacker identity.

`100940` uses the existing JSON parent `100900`; do not duplicate the parent or add an unnecessary decoder. Test location-dependent classification with:

```bash
sudo /var/ossec/bin/wazuh-logtest -l /var/log/zeek-custom/icmp_flood.log
```

Paste a reduced JSON Zeek sample, not an `alerts.json` wrapper. See [`../../../scenarios/icmp-flood/README.md`](../../../scenarios/icmp-flood/README.md) and [`../../../evidence/icmp-flood/README.md`](../../../evidence/icmp-flood/README.md).

## MITM and SSH coverage

The MITM rules `100930-100932` classify suspected ARP binding mismatch, rogue DHCP server, and protected-DNS anomaly respectively. SSH rules distinguish ordered `(source, destination)` pairs; `120940` represents fan-out and `120941` fan-in. These IDs and their validation data are unrelated to `100940` despite overlapping numeric prefixes.

## Reverse-shell to scanning correlation

Rules `120927-120934` follow previously matched reverse-shell correlation rules and require the later scanning event to have the same `src_ip` inside a 900-second window.

| New rule | Earlier reverse-shell rule |
|---:|---:|
| `120927` | `120901` |
| `120928` | `120904` |
| `120929` | `120907` |
| `120930` | `120910` |
| `120931` | `120914` |
| `120932` | `120917` |
| `120933` | `120921` |
| `120934` | `120924` |

## AppArmor rules

The AppArmor rules start with generic denial rule `130900` and specialize file read/write denial, executable denial, shell/interpreter/tool execution, Linux capabilities, network operations, ptrace, mount, signal, D-Bus, sensitive files, persistence paths, and repeated-denial behavior.

High-severity examples include:

- `130920`: blocked shell execution;
- `130931`: high-risk Linux capability denial;
- `130963`: persistence-related modification denial;
- `130964`: security-monitoring modification denial;
- `130981`: repeated executable-launch denials.

## Validation

```bash
sudo /var/ossec/bin/wazuh-logtest
sudo /var/ossec/bin/wazuh-analysisd -t
```

Correlation tests require the complete event sequence, not a single isolated log line. Keep historical `scanner_ip` samples separate from the current `src_ip` schema.
