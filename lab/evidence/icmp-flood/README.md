# ICMP Flood evidence (October 2026)

Selected, minimal evidence from the v1.4-to-v1.5 Zeek/Wazuh laboratory campaign. This directory intentionally excludes full PCAPs, complete Zeek connection logs, full Wazuh alert archives, credential-bearing configurations, and VM snapshots.

## Files

| File | Contents |
|---|---|
| `zeek-icmp-flood-samples.jsonl` | Two original v1.5 operational Zeek JSON alerts supplied from ZeekVM |
| `wazuh-100940-sample.jsonl` | Reduced fields from a verified operational Wazuh alert, after description update |
| `results.tsv` | Compact test matrix with recorded observations and outcomes |

`zeek-icmp-flood-samples.jsonl` is copied from the supplied `icmp_flood.log` excerpt. The Wazuh example includes only the fields actually observed in the manager output and is **not a verbatim full alerts.json event**. Neither sample should be used to infer inter-VM delivery latency while NTP was unsynchronized.

## Key comparisons

- v1.4 fixed windows: **366 + 436** observations in two separate 5 s windows, **0 alerts**.
- v1.5 sliding window on the **same 802-observation PCAP**: maximum **800** observations in a rolling 5 s interval, **1 alert** at `1791974668.501825`.
- Offline controls: LOW 320 observations / 0 alerts; HIGH 596 / 1; MULTI 1600 / 1.
- Concurrent destinations: `10.3.20.2` and `10.3.30.3` each 800 observations and one alert.
- Continuous traffic: 5600 observations, two alerts exactly 30 seconds apart.
- Spoofed lab address `10.3.20.250`: captured 800 observations to `10.3.30.3`; the detector preserves `source_attribution=unverified`.
- Preliminary performance: 4800 ICMP observations; no drops reported by temporary Zeek instance; 20-second mean process CPU 0.70%, RSS approximately 243 MiB. The load/sample alignment and incremental detector overhead were not isolated.

## Observation scope

The OVS mirror duplicates some routed frames. An observation is a Zeek `icmp_echo_request` event, **not** a unique Echo Request on the wire. Sensor rate and threshold should not be described as verified unique packet rates.

For methodology and the limitations of the dataset, see [`../../scenarios/icmp-flood/README.md`](../../scenarios/icmp-flood/README.md).
