# ICMP Echo Flood — Zeek v1.7-rc2 (validated laboratory configuration)

**Status (2026-10-19):** functional end-to-end validation completed on the Proxmox/OVS routed test path. `enforce` is an **experimental, topology-dependent** mirror-deduplication heuristic, not a general-purpose DDoS prevention system. This detector identifies the *destination*; the attacker's true identity remains unverified.

## Module layout

| File | Purpose |
|---|---|
| `__load__.zeek` | Single module entry point: detector followed by policy |
| `icmp_flood.zeek` | IPv4 Echo Request events, per-target exact sliding window, bounded timestamp ring, cooldown, JSON logging |
| `dedup.zeek` | Bounded per-target fingerprint cache and TTL 1-step, one-to-one mirror-pair matching |
| `config.zeek` | Site-specific protected subnets, exclusions, lab thresholds and `enforce` mode |
| `test_threshold.zeek`, `test_multi_target.zeek` | Historical v1.5 PCAP regressions with `dedup_mode="off"`; **not** runtime policy |
| `run_offline_tests.sh` | Executes historical four-PCAP tests with local, separately retained captures |

Do not load `test_*.zeek` from the operational ZeekControl configuration.

## Load with one line

The lab's `/opt/zeek/share/zeek/site/local.zeek` needs only:

```zeek
@load custom_scripts/icmp_flood
```

`__load__.zeek` loads `icmp_flood.zeek` and then `config.zeek`. Avoid adding network-specific `redef` statements to `local.zeek` or loading `icmp_flood.zeek` directly; doing so bypasses the policy file. This exact configuration mistake initially caused a missed alert for `10.3.20.2`, and was fixed and retested.

## Policy currently validated

The committed [`config.zeek`](config.zeek) enables automatic target selection inside **10.3.10.0/24**, **10.3.20.0/24** and **10.3.30.0/24**. Monitoring excludes destinations in `excluded_targets` (empty by default). The old `monitored_targets` static set is retained for backward compatibility. All target lists are explicit to avoid accidentally monitoring unrelated address space.

| Configuration | Value | Scope |
|---|---|---|
| `window_length` | 5 s | Exact sliding window, independent per destination |
| `threshold_packets` | 500 | Number of **estimated distinct** Echo Requests required in `enforce` |
| `alert_cooldown` | 30 s | Per destination; another destination can alert during cooldown |
| `dedup_mode` | `enforce` | Experimentally validated; `observe` and `off` also supported |
| `dedup_window` | 2 ms | Strict pairing interval |
| `dedup_max_signatures` | 1024 | Capacity per active destination |
| `dedup_max_payload_bytes` | 1024 | Larger payloads fail open (counted, not hashed) |
| `target_idle_timeout` | 10 min | Unused destination sliding state expiration |
| `dedup_idle_timeout` | 10 min | Unused destination signature-cache expiration |
| `metrics_enabled` | `F` | Extra fixed-window diagnostic log disabled |

**Interpretation:** on the validated inter-VLAN path, OVS mirrors both pre-routing and post-routing Echo Requests. The detector originally observed about two frames per actual request. In `enforce`, likely mirror copies are excluded from the threshold ring. The field `observed_packets` remains `500` for schema compatibility, but `counting_basis` is now `estimated_unique_echo_requests`, **not** a verified unique packet count.

## Exact sliding window and ring

An `icmp_echo_request(c, info, id, seq, payload)` event is accepted only for a monitored IPv4 destination. The detector keeps only the latest `K = threshold_packets` timestamps per target in a circular buffer and triggers whenever the oldest-to-newest span of those K observations is **strictly less** than 5 seconds. It does not reset the ring at fixed boundaries. Fixed-window diagnostics are kept separately and cannot trigger the alert.

Memory is bounded **per active destination** by a ring of K timestamps and 1024 fingerprint slots, while total usage still depends on the number of active destinations and expires after inactivity. The implementation has not been benchmarked for arbitrary high-cardinality or production loads.

## TTL decrement and one-to-one deduplication

The [`dedup.zeek`](dedup.zeek) script computes a SHA-256 fingerprint over observed source, destination, Echo ID/sequence and payload **without TTL**. A newer observation is a candidate mirror copy only if all hold:

1. Same fingerprint and destination;
2. It follows the previous observation in strictly less than 2 ms;
3. Previous observed IPv4 TTL is **exactly 1 greater** than the current TTL (lab-verified `64 -> 63`);
4. The earlier reference has not already been consumed by another match.

Same-TTL repeats, reversed TTL sequences, out-of-window observations, and oversized payloads fail open and count normally. This reduces accidental collisions relative to the old 10-ms fingerprint-only method, but does **not** prove packet identity. A maliciously or naturally identical pair with matching TTL progression might be misclassified, and other network paths may not follow the same TTL ordering. Only enable `enforce` after topology-specific verification.

## Data contract and Wazuh

Zeek writes `/var/log/zeek-custom/icmp_flood.log` as JSON. `wazuh-agent` collects that exact file, and Manager rule `100940` (level 8, ATT&CK T1498.001) matches `event_type=icmp_flood_suspected` and the log's location. A change to the **wording** of the repository's rule description makes it valid for both raw and estimated-unique modes; the rule ID, matching logic and severity are unchanged.

| JSON field | Meaning |
|---|---|
| `dest_ip` | Monitored destination (not authenticated attacker source) |
| `event_type` | `icmp_flood_suspected` |
| `alert_phase` | `sliding_threshold_crossed` |
| `dedup_mode` | `observe`, `enforce` or `off` |
| `counting_basis` | `raw_mirror_observations` or `estimated_unique_echo_requests` |
| `dedup_match_policy` | `ttl_decrement_one_to_one` in v1.7-rc2 |
| `observed_packets` | Configured threshold (`500`); **consult counting_basis** |
| `threshold_elapsed_seconds` | Span between oldest and newest of the last K counted observations |
| `threshold_trigger_pps` | K/span, per second, in the selected counting basis |
| `raw_observations_in_diagnostic_window` | Current fixed diagnostic-window raw count, *not* the trigger sliding-window raw count |
| `estimated_unique_in_diagnostic_window` | Current fixed-window estimate of countable observations |
| `duplicate_candidates_in_diagnostic_window` | Current fixed-window count of matched candidates |
| `source_attribution` | `unverified`; source-based RouterOS quarantine is **not enabled** |

Diagnostic fields above describe a fixed window that happens to be active when the sliding trigger occurs. Do not misrepresent them as exact counts inside the trigger's rolling window. The nominal field `observed_pps = 500 / 5 = 100` is not the measured trigger intensity.

## Live validation, 2026-10-19

- `observe` mode: 500 raw mirror observations, 250 estimated distinct, 250 candidates, Wazuh rule `100940` generated.
- Independently verified mirroring: `tcpdump` saw **20 observations from 10 ping requests**, each pair with identical IP ID/Echo ID/sequence, TTL `64 -> 63`, and 25–77 microseconds separation; 0 reported capture drops for this short sample.
- `enforce` in v1.7-rc1: a 400-ping bounded test produced no new matching alert, while 600 pings / 2.994 seconds generated an alert at 500 estimated distinct requests (`999` raw and `499` candidates at trigger); Wazuh rule `100940` generated.
- **v1.7-rc2**: 600 ping requests / 2.992 seconds produced a threshold alert with `dedup_match_policy=ttl_decrement_one_to_one`, `999` raw diagnostic observations, `500` estimated distinct and `499` candidate mirrors. Wazuh rule `100940` received the same Zeek event timestamp.

These are controlled functional checks, not a population-level false-positive rate or proof of service outage. See [the scenario](../../../../../scenarios/icmp-flood/README.md), [validation](../../../../../docs/icmp-flood-validation-2026-10.md), and [sanitized evidence](../../../../../evidence/icmp-flood/README.md).

## Historical offline regression

Run the existing four-PCAP historical sliding-window test in a separate Zeek process (PCAP files excluded from the public repo):

```bash
cd /path/to/icmp_flood
PCAP_DIR="$HOME/icmp-debug" bash ./run_offline_tests.sh
```

The test overrides explicitly set `dedup_mode="off"`, reproducing the original **raw** v1.5 counts and the fixed/sliding boundary case. They do **not** by themselves validate the v1.7 TTL pairing. Live `tcpdump` and Zeek/Wazuh reduced events provide the latter evidence.

## Operational verification and rollback

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl status
```

Only after an approved configuration change, run `sudo /opt/zeek/bin/zeekctl deploy` and verify status; deploy restarts sensor workers and may temporarily interrupt observation. Preserve a backup of the three operational scripts plus `__load__.zeek` and `local.zeek`. The source repository does not deploy automatically.

## Limits

- Validated on a specific lab mirror path and a small number of hosts. A TTL-based match may behave differently on asymmetric paths or packet generators with repeated signatures.
- An alert indicates a configured traffic-rate anomaly, **not** proven denial of service; 400/600 controlled pings both had 0% loss in observed tests.
- NTP was verified on both ZeekVM and WazuhVM on 2026-10-16 using `systemd-timesyncd`. Later Zeek-to-Wazuh timestamp differences are available as individual observations; they are not isolated network latencies or an aggregated performance claim.
- `source_attribution=unverified` and no automatic source quarantine, especially with IP spoofing.
- Full PCAPs, detailed packet payloads and credential-bearing artifacts are intentionally excluded.
