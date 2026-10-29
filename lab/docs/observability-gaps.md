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

## Data Exfiltration visibility and attribution limits

- The final module estimates **originator-to-responder TCP payload bytes on finalized connections** using sequence-derived information. It is not packet-by-packet wire-time accounting or verified receiver-side delivery; the T01–T10 tests separately checked bytes received by the authorized test sink.
- Mirroring, incomplete TCP handshakes, capture gaps, retransmissions and first/partial windows can affect eligibility. Quality-excluded windows do not become confirmed Adaptive candidates, even when the byte estimate is high.
- The Adaptive baseline requires delayed benign sample confirmation and is **in memory**. Its `ready` state is workload-dependent and resets on Zeek redeployment; a suspicious candidate can pause learning to avoid baseline contamination.
- Slow detection covers a tested ten-window pattern, not every possible low-rate exfiltration strategy. Long gaps, alternative timing, mixed flows or below-threshold volumes may evade it.
- Host aggregates can summarize several destinations. `111945` and `111946` correlate by `src_ip` and **do not enforce destination uniqueness**; `111948` may describe persisted rolling state with no new bytes in an individual continuation window.
- Detection cannot determine the initiating process, file contents, destination ownership, intent, or whether sensitive material was actually disclosed. The separate Auditd/AppArmor telemetry is **not** correlated into these exfiltration XML rules.
- Legitimate backups, cloud synchronization, software distribution or other bulk data transfers can resemble suspicious volumes. The ten controlled PASS results do not establish a production false-positive or false-negative rate.
- The Zeek Agent forwards only selected candidate/continuation JSON events, while many diagnostic records remain in the local log; absence of an alert does not mean absence of a local diagnostic event.
- No scenario-specific automated quarantine, endpoint blocking or Python correlation service is enabled.

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
