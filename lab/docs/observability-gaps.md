# Observability Gaps

## Network visibility

- Zeek observes only traffic delivered to the mirrored capture path.
- Packet loss or incorrect OVS/VLAN configuration can produce incomplete sessions.
- Encrypted application payloads are not inspected without decryption.
- Reverse-shell detection is heuristic and does not prove attacker intent by itself.
- ARP-based host scanning is visible only when the relevant broadcast/link-layer traffic reaches the sensor.

## Scanning detection limitations

- `address_scan` and `icmp_host_scan` currently use a threshold of two unique targets in 60 seconds; this is intentionally aggressive for lab validation and can create false positives.
- `port_scan` and `udp_port_scan` count unique destination ports within a short window and may miss slow reconnaissance spread across longer periods.
- A scanner that changes source address or distributes probes across hosts can evade same-source aggregation.
- Historical logs used both `scanner_ip` and `src_ip`; current correlation expects `src_ip`.
- The custom scripts detect patterns, not the identity or intent of the scanning tool.

## Endpoint visibility

- Auditd captures only configured syscalls/watches.
- The current `connect()` rule focuses on authenticated users and can miss service/kernel/container activity outside its filters.
- Fixed syscall numbers can be architecture-specific.
- Short-lived processes may terminate before evidence collection runs.

## AppArmor limitations

- AppArmor events describe policy decisions, not proof of compromise.
- Complain mode logs policy violations but does not prevent them.
- An incomplete profile may either miss intended restrictions or block legitimate service behavior after switching to enforce mode.
- The current profile is tailored to the controlled inventory service and is not a generic server-hardening profile.
- Wazuh rules classify denials after the kernel/AppArmor decision; they are not the enforcement mechanism.

## Correlation limitations

- Cross-agent timing and event order can affect correlation.
- `same_field` matching requires normalized, identical field values.
- Long correlation windows increase the chance of unrelated events being combined.
- Reverse-shell-to-scanning correlation currently uses source IP as the primary linkage; stronger host identity or process/session linkage would reduce ambiguity.

## Data-exfiltration limitations

- A volume anomaly can represent legitimate backups, updates, or transfers.
- Baselines are sensitive to the learning period and workload changes.
- Low-and-slow transfers may remain below the threshold.

## Response limitations

- Evidence collection is a point-in-time snapshot.
- RouterOS quarantine depends on SSH availability, firewall ordering, connection tracking, and correct victim-IP extraction.
- Automatic endpoint process termination and automatic quarantine rollback are not claimed as implemented.
- A least-privilege RouterOS permission model should be preferred over broad write permissions.

## Current scenario gaps

- No dedicated custom correlation is documented for the later pivot/port-forward stage.
- Dedicated SSH password-brute-force correlation for the final attack-chain stage is not part of this update.
- Command-injection visibility is demonstrated primarily through AppArmor/Audit effects; a dedicated application-layer command-injection detector is not part of this update.

## Future improvements

- Tune scanning thresholds with a longer benign traffic baseline.
- Add regression tests for Zeek schemas, Wazuh decoders, and rule IDs.
- Add explicit host identity/session correlation beyond source IP.
- Hash and centrally protect evidence archives retained outside the public repository.
- Add dedicated SSH authentication-failure detection/correlation if the final attack-chain stage is kept.
- Add response approval/recovery workflows where operational use requires them.
