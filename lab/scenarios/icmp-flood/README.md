# ICMP Echo Flood: exact sliding detection, subnet monitoring and OVS mirror deduplication

**Status (2026-10-19):** v1.7-rc2 validated end-to-end on the routed test path (Zeek + Wazuh). Not a statistically calibrated production intrusion-detection rule. Historic v1.4/v1.5 evidence is retained below and must not be conflated with the v1.7 deduplicated counting basis.

## Objective

Detect elevated ICMP Echo Request traffic directed at a monitored destination, including traffic whose IPv4 source address is spoofed, by combining Zeek packet-event telemetry with Wazuh alerting. Demonstrate and correct a specific false negative caused by non-overlapping windows.

The experiment targets the **observed destination**; it deliberately does not attempt to identify the attacker from an unauthenticated IP header or trigger automatic RouterOS quarantine.

## Topology and observation scope

```text
Client-Linux (10.3.20.2) ---- VLAN 20 -----+
                                            | RouterOS routing
ServerDB (10.3.30.3) ----- VLAN 30 --------+
                                            |
                         OVS mirrored VLANs 10/20/30
                                            |
                                  VLAN 999, ens19.999
                                            |
                                  ZeekVM 10.3.10.2
                                            |
             /var/log/zeek-custom/icmp_flood.log (JSON)
                                            |
                                        Wazuh Agent
                                            |
                               Wazuh Manager 10.3.10.3
                                            |
                           Rule 100940, level 8, T1498.001
```

The historical v1.5 path produced approximately **two mirror observations per ICMP Echo Request** (pre- and post-routing). The v1.5 detector counted mirrored observations; the later v1.7 estimate uses a separately validated TTL-pair heuristic. A separate locally retained PCAP and an independent sliding-window calculation were used to validate the boundary case.

## Current deployment: v1.7-rc2

The operational Zeek module is loaded from `local.zeek` using **only** `@load custom_scripts/icmp_flood`. Its [`__load__.zeek`](../../blue-team/zeek/site/custom_scripts/icmp_flood/__load__.zeek) loads the detector and the subnet-specific [`config.zeek`](../../blue-team/zeek/site/custom_scripts/icmp_flood/config.zeek). It monitors IPv4 destinations inside VLANs 10, 20 and 30 (`10.3.10.0/24`, `10.3.20.0/24`, `10.3.30.0/24`), keeping independent sliding windows and 30-second cooldowns per target.

The detector uses `dedup_mode="enforce"` **only in this controlled lab**, with a two-millisecond, one-to-one TTL decrement (`64 -> 63`) mirror-pair policy. It requires 500 **estimated distinct** Echo Requests in strictly less than five seconds to generate a JSON alert; `estimated distinct` is not cryptographically proven packet uniqueness. A 10-minute idle-time expiry releases per-target state, and `dedup_max_signatures=1024` bounds each active target's signature ring. Automatic RouterOS quarantine is not enabled for this detector because the source IP may be spoofed.

See [the current detector module README](../../blue-team/zeek/site/custom_scripts/icmp_flood/README.md) for the precise matching conditions and fields.

## Historical v1.5 implementation snapshot

| Setting | Value in tested laboratory |
|---|---|
| Script | `blue-team/zeek/site/custom_scripts/icmp_flood/icmp_flood.zeek` v1.5 |
| Monitored target (default) | `10.3.30.3` |
| Window | Exact sliding 5 s |
| Trigger | 500 observations in the last 5 s |
| Cooldown | 30 s, independently keyed per victim |
| Alert output | `/var/log/zeek-custom/icmp_flood.log` |
| Diagnostic metrics | Separate stream, off by default |
| Wazuh rule | `100940`, level 8, MITRE ATT&CK `T1498.001` |
| Source attribution | `unverified` |
| Automatic quarantine | Not enabled for this detector |

The circular buffer retains only the latest K observation timestamps per monitored destination, not an unbounded per-packet history. The 5-second fixed-window diagnostic metrics are separate from the sliding detector.

## Methodology and observed results

The same detector and captured inputs were checked both offline and, where stated, against live mirrored traffic. Separate Zeek instances used isolated log paths; the operational ZeekControl detector was not modified until the offline and live tests passed.

| Test | Recorded observations | Result | Interpretation |
|---|---:|---|---|
| LOW offline (`icmp-calibration-long.pcap`) | 320 | 0 alerts | Negative control in tested baseline |
| HIGH offline (`icmp-calibration-298.pcap`) | 596 | 1 alert | Positive control |
| MULTI offline (`icmp-multiwindow.pcap`) | 1600 | 1 alert | Alert suppression during cooldown |
| BOUNDARY v1.4 | 366 + 436 | 0 alerts | Fixed-window false negative |
| BOUNDARY v1.5, same PCAP | 802 total | 1 alert | Sliding-window fix; alert at `1791974668.501825` |
| Live multi-victim (one target above threshold) | A 800 / B 320 | 1 / 0 alerts | Independent destination counters |
| Live dual-target (both above threshold) | 800 / 800 | 1 / 1 alerts | Independent counters and alert cooldowns |
| Sustained live traffic | 5600 over 9 diagnostic windows | 2 alerts, 30 s apart | Re-arm during continuous traffic |
| Controlled spoofed-source traffic | 800 observations | 1 alert in detector test | Destination detection despite spoofed source |
| Preliminary performance | 4800 observations | 1 alert; no capture drops | Sampled CPU/RSS and capture test |
| Wazuh integration v1.5 | Real Zeek JSON event | Rule `100940` | Manager alert verified after rule description update |

### Boundary false negative and fix

A normal Echo Request initializes the old fixed window; the following bounded ICMP burst is distributed across two adjacent diagnostic windows. With threshold 500 observations/5 s, fixed windows reported **366** and **436** observations, neither above 500, and produced **no alert**. The very same 802-observation capture has a **maximum of 800 observations in a rolling 5-second interval**. The v1.5 exact sliding window generated an alert precisely when the 500th observation fell into the rolling interval, matching an independent `tcpdump`/`awk` calculation to the reported timestamp resolution.

This is a **demonstrated false negative for the specific v1.4 configuration and PCAP**, not a population-level false-negative rate.

### Multi-victim independence

Two contemporaneous bounded streams (to `10.3.20.2` and `10.3.30.3`) each produced 800 observations and **one alert per destination**. The alerts were approximately two seconds apart, within a 30-second cooldown period: one victim's cooldown did not suppress the other victim.

### Cooldown under sustained traffic

The sustained experiment produced exactly two threshold alerts 30 seconds apart and nine diagnostic windows totalling 5600 observations. `cooldown_suppressed=true` in a diagnostic window indicates at least one suppressed trigger attempt; it does **not** count the number of suppressed alerts.

### Source-address spoofing

Controlled lab traffic used an unassigned laboratory address `10.3.20.250` as the packet's apparent source. The `conn.log` of the detection run included that address; a separate capture of a repeated run verified 800 mirrored Echo Request observations with `10.3.20.250` as the source. The detector emitted one event for destination `10.3.30.3` with `source_attribution=unverified`. The first narrowly filtered PCAP was empty, so the repeat was necessary to substantiate this result. The two captures are **not** represented as the same run.

### Preliminary performance

In the bounded ~200 Echo Request/s scenario, Zeek processed 4800 mirrored observations and the instance reported 12145 total packets received, **0 dropped and 0 unprocessed**. The 20-second `pidstat` sample reported mean Zeek process CPU ~0.70% and mean RSS 248809 KiB (~243 MiB). These figures reflect the **whole Zeek instance** and the sampled period, not the incremental cost of only the ICMP detector or a maximum sustainable rate. Additional replicated, aligned baseline/loaded trials are needed before performance claims.

## Subsequent v1.6/v1.7 results (16–19 October 2026)

| Version / configuration | Bounded experiment | Zeek | Wazuh |
|---|---|---|---|
| v1.6-rc2 subnet monitoring | Client `10.3.20.2` -> ServerDB `10.3.30.3`, 400 ping requests | 500 raw observations / 2.739 s | Rule `100940` |
| v1.6-rc2 subnet monitoring | ServerDB `10.3.30.3` -> newly monitored Client `10.3.20.2`, 400 requests | 500 raw observations / 2.738 s | Rule `100940` |
| v1.7-rc1 `observe` | ServerDB -> Client, bounded test | 500 raw / 250 estimated distinct / 250 candidate mirrors | Rule `100940` |
| v1.7-rc1 `enforce`, negative control | 400 requests / 4.389 s | No new matching `enforce` alert in inspected log | Not asserted separately |
| v1.7-rc1 `enforce`, positive | 600 requests / 2.994 s | 999 raw / 500 estimated distinct / 499 duplicate candidates at trigger | Rule `100940` |
| **v1.7-rc2 `enforce`**, TTL one-to-one | **600 requests / 2.992 s** | **999 raw / 500 estimated distinct / 499 candidates; match policy `ttl_decrement_one_to_one`** | **Rule `100940` with same Zeek event timestamp** |

A dedicated `tcpdump` sanity check of ten normal ping requests recorded twenty mirrored observations. Each original request was seen with the same IP ID, ICMP identifier and sequence number, with TTL 64 before and 63 after routing; the pair separation was 25–77 µs, and this short capture reported zero kernel drops. This independently supports the chosen pair-matching heuristic **on the tested network path only**.

NTP synchronization was verified on both VMs on 16 October. In the final v1.7-rc2 test the Zeek event `1792419630.409220` and Wazuh alert `2026-10-19T14:20:32.507+0000` corresponded to a timestamp difference of **2.097780 seconds**. This covers multiple logging/transport/processing stages, not solely wire latency. It is a single observation and must not be generalized. All reduced records are in [the evidence directory](../../evidence/icmp-flood/README.md).

## Example controlled verification

Only run against authorized, isolated lab targets. The following is the **historical v1.5 raw-observation** positive check; **it is not guaranteed to reach 500 estimated-distinct observations in v1.7 `enforce`**:

```bash
sudo ping -n -q -i 0.01 -c 400 -W 1 10.3.30.3
```

On ZeekVM:

```bash
sudo tail -n 3 /var/log/zeek-custom/icmp_flood.log | jq -c '{ts,event_type,dest_ip,observed_packets,alert_phase,threshold_trigger_pps,source_attribution}'
```

On Wazuh Manager:

```bash
sudo jq -c 'select(.rule.id=="100940" and .data.alert_phase=="sliding_threshold_crossed") | {timestamp,rule_id:.rule.id,description:.rule.description,dest_ip:.data.dest_ip}' /var/ossec/logs/alerts/alerts.json | tail -n 3
```

To test a captured event directly with Wazuh, set its original location (this is required by rule 100940):

```bash
sudo /var/ossec/bin/wazuh-logtest -l /var/log/zeek-custom/icmp_flood.log
```

Pasting JSON into `wazuh-logtest` **without** `-l` matches only parent `100900`, because the child rule has a `<location>` constraint.

## Reliability and limitations

1. **Threshold not calibrated:** `500/5s` is experimental. In historical v1.5 it counts mirrored observations; in v1.7 `enforce` it counts **heuristically distinct** observations. Neither basis is a verified universal packet rate; do not reuse the threshold on unrelated paths.
2. **Source authenticity:** IP addresses in ICMP packets can be spoofed. This detection does not establish attacker identity and is not wired to source-based RouterOS quarantine.
3. **No service-outage proof:** successful alerting does not demonstrate destination exhaustion, packet loss or actual denial of service.
4. **Inter-VM time:** NTP was not synchronized during the **early v1.5** trials, so historical cross-VM differences are invalid as latency measures. NTP was verified on both VMs on 2026-10-16; the later v1.6/v1.7 table reports only individual differences. The recorded `threshold_elapsed_seconds` is within the Zeek observation sequence, not Zeek-to-Wazuh latency.
5. **Packet capture warnings:** a checksum-offloading warning appeared in some live runs. In the isolated tests the ICMP observations were parsed and the Zeek capture statistics reported zero drops; this does not establish universal absence of packet-loss elsewhere.
6. **Coverage:** this is an Echo Request anomaly detector for configured IPv4 destinations. It does not detect all network floods and is not a production DDoS mitigation system.
7. **Reproducibility:** reduced alert samples, a test index and the Zeek regression harness are published. Full PCAP files, complete raw telemetry and credentials are intentionally excluded.

See [`../../evidence/icmp-flood/README.md`](../../evidence/icmp-flood/README.md), the [detector README](../../blue-team/zeek/site/custom_scripts/icmp_flood/README.md), and [`../../docs/icmp-flood-validation-2026-10.md`](../../docs/icmp-flood-validation-2026-10.md).

8. **TTL deduplication remains heuristic:** one-to-one TTL transitions can still pair distinct crafted packets; other routing topologies may not exhibit `64 -> 63` in the same observation order.
