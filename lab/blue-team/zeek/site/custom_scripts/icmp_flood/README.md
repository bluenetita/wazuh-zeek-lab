# ICMP Echo Flood detector (Zeek v1.5)

This detector was validated in the Proxmox cyber range in October 2026. It detects **anomalous ICMP Echo Request observation rates for explicitly monitored destinations**. It is not a general-purpose DDoS classifier and does not identify a genuine sender when source addresses can be spoofed.

## Files

| File | Purpose |
|---|---|
| `icmp_flood.zeek` | Detector used by the monitored Zeek instance |
| `test_threshold.zeek` | Safe configuration override for offline regression / an isolated Zeek instance |
| `test_multi_target.zeek` | Overrides monitoring targets for a two-destination experiment |
| `run_offline_tests.sh` | Four regression tests using PCAP captures stored locally, outside Git |

Only `icmp_flood.zeek` is loaded from the production `local.zeek`. **Do not load the test overrides in ZeekControl.**

## Detection algorithm

- Filter IPv4 `icmp_echo_request` observations by the configured destination set.
- Keep the most recent `threshold_packets` observation timestamps per destination in a bounded circular buffer.
- Trigger as soon as the last `threshold_packets` observations fall within a **sliding** interval of `window_length`.
- Maintain per-destination cooldown. A sustained stream can trigger again after cooldown expires.
- Keep separate, fixed-window diagnostic counters for comparison; these counters **do not** determine detection.

The default configuration is:

```zeek
const monitored_targets: set[addr] = { 10.3.30.3 } &redef;
const window_length: interval = 5sec &redef;
const threshold_packets: count = 500 &redef;
const alert_cooldown: interval = 30sec &redef;
const log_path: string = "/var/log/zeek-custom/icmp_flood" &redef;
const metrics_enabled: bool = F &redef;
```

Tune these settings for the monitored environment; 500 observations per five seconds is a **laboratory threshold**, not a validated production baseline. The ring requires `threshold_packets >= 1`, and memory grows with `threshold_packets` times the number of observed/monitored destinations.

## Placement and loading

On the ZeekVM, copy `icmp_flood.zeek` to:

```text
/opt/zeek/share/zeek/site/custom_scripts/icmp_flood/icmp_flood.zeek
```

Load it once from `/opt/zeek/share/zeek/site/local.zeek`:

```zeek
@load custom_scripts/icmp_flood/icmp_flood.zeek
```

The lab uses the OVS mirror interface `ens19.999`. Zeek logs are in JSON format via the existing site policy. The runtime log is `/var/log/zeek-custom/icmp_flood.log`; if enabling diagnostics for a test, a second stream `/var/log/zeek-custom/icmp_flood_metrics.log` is available. Leave metrics disabled in the deployed configuration unless needed.

The companion Wazuh agent reads **only** `/var/log/zeek-custom/icmp_flood.log` for this scenario; rule `100940` matches its location and `event_type=icmp_flood_suspected`. See the [scenario](../../../../../scenarios/icmp-flood/README.md) and [evidence](../../../../../evidence/icmp-flood/README.md).

## Alert fields

| Field | Interpretation |
|---|---|
| `event_type` | `icmp_flood_suspected` |
| `dest_ip` | Destination under observation; **not** attacker attribution |
| `observed_packets` | Threshold observation count at trigger (normally 500) |
| `window_seconds` | Maximum sliding interval (normally 5 s) |
| `observed_pps` | Nominal count / 5 s, **not** effective packet rate at trigger |
| `threshold_elapsed_seconds` | Span from oldest to newest observation among the last K at trigger |
| `threshold_trigger_pps` | K divided by the measured span |
| `alert_phase` | `sliding_threshold_crossed` |
| `detection_reason` | `destination_echo_sliding_window_threshold` |
| `source_attribution` | `unverified` |
| `observation_scope` | `mirrored_traffic_not_deduplicated` |

On the validated OVS routed path a single ICMP Echo Request was generally seen twice (ingress + egress). **500 Zeek observations are not necessarily 500 distinct requests.** Do not indiscriminately divide by two: topology, direction, drops, and VLAN paths can change the duplication ratio.

`threshold_trigger_pps` is an average rate over the threshold observation span, not a count of unique wire packets and not a measure of time-to-Wazuh.

## Offline regression

With locally retained PCAPs, Zeek, Bash, `awk`, and `jq` installed:

```bash
cd /path/to/icmp_flood
PCAP_DIR="$HOME/icmp-debug" bash ./run_offline_tests.sh
```

Expected PCAP names in `PCAP_DIR` (not committed):

```text
icmp-calibration-long.pcap
icmp-calibration-298.pcap
icmp-multiwindow.pcap
icmp-boundary-v1_4.pcap
```

Expected cases: LOW 320 observations / 0 alerts, HIGH 596 / 1, MULTI 1600 / 1, BOUNDARY 802 / 1. In the BOUNDARY capture, the older v1.4 detector saw 366 + 436 observations in separate fixed windows and emitted no alert. The v1.5 detector emitted at Unix timestamp `1791974668.501825`, exactly where the independently computed sliding counter first reached 500 observations.

The script **depends on captures from this experimental campaign** and does not make the repository self-contained without those captures. PCAPs are excluded from public Git publication because they can contain unrelated lab traffic.

## Verification and rollback

Before modifying the live VM, back up the destination file, then run:

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl deploy
sudo /opt/zeek/bin/zeekctl status
```

On failure, restore the backup and re-run `check` and `deploy`. This repository update **does not execute deployment commands**.

## Limitations

- Counts mirrored observations without flow-path de-duplication.
- No reliable sender identity under IP source spoofing; automatic source-IP quarantine is deliberately excluded.
- Detection considers IPv4 Echo Requests for configured targets; it does not cover all ICMP traffic or every DDoS vector.
- A threshold crossing indicates an anomaly in this controlled baseline, not independently verified service unavailability.
- Timings reported from Zeek packet timestamps are intra-sensor; inter-VM latency measurements require synchronized clocks.
- CPU/RSS observations reflect the complete test Zeek process and a sampled interval, not a per-script profiler.
