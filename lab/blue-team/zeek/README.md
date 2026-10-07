# Zeek

Zeek is the Network Security Monitoring sensor for the cyber range. It receives traffic mirrored by Open vSwitch and produces both standard logs and custom logs forwarded to Wazuh.

## Observation point

```text
VLAN 10 / 20 / 30
        |
   OVS mirror
        |
     VLAN 999
        |
     ZeekVM
        |
   Wazuh Agent
```

The mirror interface used in the lab is `ens19.999`.

## Main files

| File | Function |
|---|---|
| `site/local.zeek` | JSON logging and loading of custom scripts |
| `site/custom_scripts/reverse_shell/reverse_shell_movement.zeek` | movement detector v2 |
| `site/custom_scripts/scanning/address_scan.zeek` | TCP address-scan detector |
| `site/custom_scripts/ssh_bruteforce/ssh_bruteforce.zeek` | SSH detection keyed by source/destination pair |

Other scripts already present in the repository (`reverse_shell.zeek`, malware/download detection, scanning loader, logging, exfiltration, and other detectors) should be preserved.

## Custom logs

Custom logs are written under `/var/log/zeek-custom/`. The most relevant are:

```text
possible_malware.log
reverse_shell_live.log
reverse_shell_movement.log
reverse_shell_final.log
scanning.log
ssh_bruteforce.log
```

The movement detector v2 also maintains a dedicated diagnostic log for experimental verification.

## Reverse-shell movement v2

The detector considers TCP connections toward destinations outside the excluded internal subnets and applies the main condition:

```text
duration >= 30 s
orig_pkts > 10
resp_pkts > 10
```

The older average-packet-size values are retained only for diagnostics. The connection is reevaluated periodically and when packets are observed; each connection emits at most one movement event.

Packet-based counters can be affected by mirror duplicates or retransmissions, so the heuristic is not equivalent to definitive reverse-shell identification.

## SSH brute force

The SSH script maintains state for:

```text
[src_ip, dest_ip, dest_port]
```

When Zeek has an inferred authentication result, it uses that path. When the outcome is unavailable on encrypted traffic, the fallback counts repeated SSH connections and produces a candidate such as:

```text
failed_connections = 0
unknown_connections = 5
auth_attempts = 0
detection_reason = repeated_ssh_connections_unknown_auth
```

This **does not** mean that Zeek observed five incorrect passwords. Authentication-failure confirmation comes from `sshd` logs collected by Wazuh.

## Scanning

Values in the final snapshot:

| Detector | Threshold | Window |
|---|---:|---:|
| TCP address scan | 20 targets | 60 s |
| TCP port scan | 100 ports | 60 s |
| UDP port scan | 50 ports | 60 s |
| ARP host scan | 20 targets | 60 s |
| ICMP host scan | 2 targets | 60 s |

The `address_scan` threshold was restored from 2 to 20 because the test value also classified simple SSH contact with two servers as a scan. This is lab tuning, not a universal baseline.

## Capture quality

During checks on `ens19.999`, GRO was observed as `off`, GSO as `on`, and LRO as `off [fixed]`. The repository does not include an unverified persistent unit that forces these values after reboot.

`ignore_checksums=T` is present in the laboratory configuration and should be reassessed in a different deployment.

## Operational checks

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl status
```

Run `zeekctl deploy` only when the sensor should actually be reloaded; a deploy can reset runtime state that may be relevant to testing.

## Limitations

Zeek does not directly observe local processes, local commands, filesystem changes, or encrypted application payloads. For those aspects, the project combines Zeek with Wazuh, Auditd, and, in mitigation scenarios, AppArmor.
