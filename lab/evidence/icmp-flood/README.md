# ICMP Echo Flood — reduced evidence (October 2026)

This folder contains selected **sanitized** evidence for the initial v1.4/v1.5 boundary regression and the final v1.7-rc2 protected-subnet / topology-dependent mirror deduplication campaign. No full PCAPs, full Wazuh alert archives, complete network log streams, passwords or private keys are published.

## Files and provenance

| File | Scope |
|---|---|
| `results.tsv` | Historical v1.4/v1.5 functional test matrix, with raw mirrored observation semantics |
| `zeek-icmp-flood-samples.jsonl` | Historical v1.5 Zeek events originally captured in October |
| `wazuh-100940-sample.jsonl` | Reduced historical Wazuh sample, not verbatim `alerts.json` |
| `v17-test-matrix.tsv` | v1.5 post-NTP, v1.6 dynamic target, v1.7 observe/enforce and final TTL-pair test outcomes |
| `v17-zeek-samples.jsonl` | Reduced **observed** Zeek v1.7 event fields provided during testing; missing fields were not invented |
| `v17-wazuh-samples.jsonl` | Reduced **observed** Wazuh 100940 fields provided during testing, including final matching `zeek_ts` |
| `ovs-mirror-pairs.tsv` | Derived from a short actual `tcpdump` transcript: 10 Echo Requests became 20 observations with TTL `64 -> 63`; no packet payloads |

The three newer JSONL files/TSVs are a **reduced field selection** from displayed terminal results, not complete original Zeek log records or unmodified `alerts.json`. The historical dataset and new data have different counting semantics, so do not aggregate rates without stratification.

## Key v1.7-rc2 result

A bounded 600-request `ping` test from `10.3.30.3` to `10.3.20.2` took 2.992 s, with 600 replies and 0% loss. At the Zeek threshold event:

```json
{"ts":1792419630.40922,"dest_ip":"10.3.20.2","observed_packets":500,"dedup_mode":"enforce","dedup_match_policy":"ttl_decrement_one_to_one","raw_observations_in_diagnostic_window":999,"estimated_unique_in_diagnostic_window":500,"duplicate_candidates_in_diagnostic_window":499}
```

Wazuh produced rule `100940` at `2026-10-19T14:20:32.507+0000` with the exact numeric Zeek timestamp as `1792419630.409220`. The zero at the end of the Wazuh string is a formatting difference, not a different timestamp. The observed Zeek-event-to-Wazuh-alert difference is **2.097780 seconds**, not an isolated network delay.

These three diagnostic counters refer to the *currently active fixed diagnostic window at the moment of the alert*, not the exact set of raw packets inside the trigger's sliding window. The detector counted 500 estimated distinct requests to reach its exact sliding trigger, but physical uniqueness is still a heuristic estimate.

## OVS two-observation path

The short `tcpdump` run counted **20 mirrored observations from 10 transmitted Echo Requests**, each with the same IPv4 ID, ICMP ID and sequence number within a pair. The first observation had TTL 64, the second 63; their timestamp differences were 25–77 microseconds. That observation motivated the strict under-2ms TTL-decrement one-to-one dedup policy. The capture reported **zero kernel drops**, but this is only for the short test and cannot prove absence of drops at other loads.

## Interpretation and limitations

- Historical v1.4 fixed windows missed a burst that the v1.5 exact sliding window detected in the same PCAP. This proves one scenario-specific false negative, **not** a real-world false-negative rate.
- v1.7-rc2 uses `estimated_unique_echo_requests`, not a verified packet identity; it may pair distinct crafted traffic or fail to match copies on different route paths, TTL orders or delays.
- The lab threshold 500/5s remains experimental; the 600-ping positive produced 0% reply loss, so **DoS service unavailability was not established**.
- IP header sources can be spoofed; the detector marks sender attribution `unverified` and does not trigger automatic RouterOS source quarantine.
- Early v1.5 inter-VM timestamps predate the verified NTP correction and should not be used to derive delays. ZeekVM/WazuhVM NTP synchronization was confirmed on 2026-10-16; later per-run timestamp differences are not a latency distribution.
- Complete PCAPs remain privately retained; the historical offline regression requires them and cannot be executed from public files alone.

See the [scenario](../../scenarios/icmp-flood/README.md), the [detector](../../blue-team/zeek/site/custom_scripts/icmp_flood/README.md), and the [validation note](../../docs/icmp-flood-validation-2026-10.md).
