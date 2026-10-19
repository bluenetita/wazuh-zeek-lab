# ICMP Flood validation: v1.5 boundary fix and v1.7-rc2 mirror deduplication — October 2026

This note accompanies [the ICMP Flood scenario](../scenarios/icmp-flood/README.md) and the [reduced evidence](../evidence/icmp-flood/README.md). The initial v1.5 PCAP trials below count **raw mirrored observations**. The separate v1.7-rc2 campaign uses **estimated distinct** Echo Request observations. The two populations are not interchangeable.

## Research question

Can an exact sliding five-second observation window detect the ICMP Echo Request burst missed by the previous detector's non-overlapping windows while retaining destination isolation, early alerting and cooldown?

## Controlled comparison

The same offline PCAP (`icmp-boundary-v1_4.pcap`, retained privately) contained 802 mirrored observations. The v1.4 diagnostic windows held 366 and 436 observations, so neither individually exceeded the threshold 500. An independent five-second sliding calculation found a maximum of 800 observations and first threshold crossing at `1791974668.501825`. The v1.5 detector generated one alert at that same packet timestamp (reported delta 0.000000 s at displayed precision).

## Regressions

| Evidence | Result |
|---|---|
| Offline low baseline | 320 observations, 0 alerts |
| Offline high | 596 observations, 1 alert |
| Offline multi-window | 1600 observations, 1 alert due to cooldown |
| Offline boundary | 802 observations, 1 v1.5 alert vs 0 v1.4 alerts |
| Live target isolation, one negative | 800 to ServerDB / 320 to Client; only ServerDB alert |
| Live two positive destinations | 800 per victim; one alert each |
| Live sustained traffic | 5600 observations; two alerts exactly 30 seconds apart |
| Spoofed apparent source | 800 observations from 10.3.20.250 in a separate verification PCAP; destination alert, source attribution unverified |
| End-to-end alert | Wazuh rule 100940, level 8, T1498.001, verified in alerts.json |
| Preliminary process resource sample | CPU avg 0.70%; RSS avg 248809 KiB; Zeek reported zero capture drops in the trial |

## Measurement cautions

1. **Mirror duplication:** OVS mirrored ingress and egress of the routed flow, causing approximately two observations per request in these captures. The multiplier is path-specific.
2. **No statistical generalization:** the small collection of controls is adequate for functional regression, not a measured real-world false-positive or false-negative rate.
3. **Timing:** Zeek's `threshold_elapsed_seconds` is an intra-detector timestamp span, not sensor-to-SIEM latency. ZeekVM and WazuhVM NTP status was **unsynchronized in the earlier v1.5 data**; those cross-host differences are invalid. Both were NTP-synchronized by 2026-10-16, permitting later *single-run* Zeek-to-Wazuh timestamp comparisons with synchronization uncertainty.
4. **Attack attribution:** spoofed source is visible as an IP header field, not the proven originator. No automatic source quarantine should be attached to these alerts.
5. **System impact:** alerting does not prove an actual denial-of-service outage on ServerDB. CPU/RSS measurements cover a temporary Zeek process, not just the incremental detector.
6. **Publication scope:** complete PCAPs and full raw logs remain outside Git. This note preserves reproducible commands through the test harness, which requires the locally held PCAPs.

## Suggested next measurements

NTP has been verified on both VMs, and selected later individual end-to-end timestamp differences are now available. Repeated baseline/load trials would still be needed before reporting population latency percentiles or false-positive rates. Re-evaluate the threshold under representative benign ICMP traffic before operational use.

## Artifacts

- Detector and regression harness: [`../blue-team/zeek/site/custom_scripts/icmp_flood/`](../blue-team/zeek/site/custom_scripts/icmp_flood/README.md)
- Wazuh rule: [`../blue-team/wazuh/rules/008_zeek_icmp_flood_rules.xml`](../blue-team/wazuh/rules/008_zeek_icmp_flood_rules.xml)
- Evidence matrix: [`../evidence/icmp-flood/results.tsv`](../evidence/icmp-flood/results.tsv)

## Follow-up validation: dynamic victims, NTP and deduplication (2026-10-16 to 2026-10-19)

- **Subnets:** v1.6-rc2 dynamically monitored targets in all three configured internal /24 VLANs. Detection toward both `10.3.30.3` and the newly selected `10.3.20.2` reached 500 mirrored observations and Wazuh rule `100940`. The initial missed `10.3.20.2` alert was traced to loading `icmp_flood.zeek` directly rather than its directory `__load__.zeek`; reloading the module fixed the issue.
- **NTP:** ZeekVM `systemd-timesyncd` reported a -106 µs source offset and WazuhVM -64 µs on 2026-10-16. The NTP source offsets **must not be subtracted** to claim an exact inter-VM offset; measurement uncertainty, distinct sources and observation times remain.
- **Observe mode:** v1.7-rc1 emitted at 500 mirrored observations; it reported 250 fingerprint candidates as duplicates and 250 estimated distinct events, without altering the alert threshold.
- **Independent packet check:** 10 ping Echo Requests were observed 20 times by `tcpdump` at the Zeek VLAN 999 mirror. Pair IP ID/ICMP ID/sequence were equal, TTL transitioned `64 -> 63`, and separation was 25–77 µs. This supports the routed-packet-copy hypothesis for that flow.
- **Enforce mode:** v1.7-rc1 negative/positive bounded tests differentiated 400 requests (no matching alert) from 600 requests (alert at 500 estimated distinct); at threshold, diagnostic fields showed 999 raw observations, 500 estimated distinct and 499 candidate duplicates. Wazuh rule `100940` matched the positive.
- **TTL one-to-one (v1.7-rc2):** 600 Echo Requests transmitted/received in 2.992 s, 0% loss. Zeek alert `1792419630.409220` with `dedup_match_policy=ttl_decrement_one_to_one`, `dedup_mode=enforce`, `counting_basis=estimated_unique_echo_requests`, `raw_observations_in_diagnostic_window=999`, `estimated_unique_in_diagnostic_window=500`, `duplicate_candidates_in_diagnostic_window=499`. Wazuh rule `100940` recorded the same Zeek timestamp. Wazuh alert time `2026-10-19T14:20:32.507+0000`; observed end-to-end event-timestamp difference **2.097780 seconds**.

**Measurement boundaries:** these 999/500/499 counters belong to the diagnostic fixed window active when the alert was emitted, not an independently reconstructed exact sliding raw/unique count. The sliding condition uses 500 *countable* timestamp observations in strictly less than five seconds. Estimated uniqueness is a fingerprint-plus-TTL heuristic, not packet provenance. Detection of high Echo Request activity does not establish loss of availability. No statistical false-positive/false-negative rate or isolated ingestion-latency distribution is claimed.

See [`../evidence/icmp-flood/v17-test-matrix.tsv`](../evidence/icmp-flood/v17-test-matrix.tsv), [`../evidence/icmp-flood/v17-zeek-samples.jsonl`](../evidence/icmp-flood/v17-zeek-samples.jsonl), [`../evidence/icmp-flood/v17-wazuh-samples.jsonl`](../evidence/icmp-flood/v17-wazuh-samples.jsonl), and [`../evidence/icmp-flood/ovs-mirror-pairs.tsv`](../evidence/icmp-flood/ovs-mirror-pairs.tsv).
