# Observability Gaps

## Network visibility

- Zeek observes only traffic delivered to the mirrored capture path.
- Packet loss or incorrect OVS/VLAN configuration can produce incomplete sessions.
- Encrypted application payloads are not inspected without decryption.
- Reverse-shell detection is heuristic and does not prove attacker intent by itself.
- ARP-based host scanning is visible only when the relevant broadcast/link-layer traffic reaches the sensor.

## Scanning detection limitations

- `address_scan` currently uses 20 unique targets / 60 s; `icmp_host_scan` uses 2 unique ICMP targets / 60 s. The latter is intentionally aggressive and can produce false positives. These two reconnaissance detectors are distinct from ICMP Echo Flood.
- `port_scan` and `udp_port_scan` count unique destination ports within a short window and may miss slow reconnaissance spread across longer periods.
- A scanner that changes source address or distributes probes across hosts can evade same-source aggregation.
- Historical logs used both `scanner_ip` and `src_ip`; current correlation expects `src_ip`.
- The custom scripts detect patterns, not the identity or intent of the scanning tool.

## ICMP Echo Flood visibility and attribution

- The OVS mirror can expose both pre-routing and post-routing IPv4 Echo Requests. In v1.7-rc2 `enforce`, TTL one-to-one pairing (same signature, 64 -> 63 transition on the tested route, under 2 ms) filters **candidate duplicates**, not provably identical packets. Other routes, ordering and adversarial collisions may defeat this heuristic.
- It uses an exact sliding window independently per destination, automatically selecting targets within configured protected subnet sets. Only IPv4 Echo Requests are covered.
- The lab threshold is `500 / 5 s` using `estimated_unique_echo_requests` with `enforce` (previously raw mirror observations in v1.5). It is not calibrated to legitimate workload and must not be copied unchanged as a general DoS rule.
- A packet's source IP may be spoofed. The Wazuh event deliberately records `source_attribution=unverified`; no automatic source-based isolation is justified from this event alone.
- Rule `100940` detects a traffic-volume anomaly, not independently verified service degradation.
- A prior v1.4 fixed-window miss was reproduced on a specific bounded PCAP; the repository does not measure an overall false-negative or false-positive rate.
- NTP was verified on both ZeekVM and WazuhVM on 2026-10-16. Later single-run event-to-alert timestamp differences are available, but encompass logging and processing and do not establish a repeatable latency distribution.

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
- The SSH brute-force scenario is documented with Zeek/sshd endpoint pair correlations; broader authentication-source coverage, replicated timing tests, and robust benign baselines remain future work.
- Command-injection visibility is demonstrated primarily through AppArmor/Audit effects; a dedicated application-layer command-injection detector is not part of this update.

## Future improvements

- Tune scanning thresholds with a longer benign traffic baseline.
- Add regression tests for Zeek schemas, Wazuh decoders, and rule IDs.
- Add explicit host identity/session correlation beyond source IP.
- Hash and centrally protect evidence archives retained outside the public repository.
- Extend the existing SSH failure/correlation coverage and replicate validation on representative benign and attack-like traffic.
- Add response approval/recovery workflows where operational use requires them.
