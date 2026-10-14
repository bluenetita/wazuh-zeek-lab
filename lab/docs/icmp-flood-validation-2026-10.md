# ICMP Flood v1.5 validation summary - October 2026

This note accompanies [the ICMP Flood scenario](../scenarios/icmp-flood/README.md) and the [reduced evidence](../evidence/icmp-flood/README.md). All observations below refer to the lab sensor's mirrored traffic and not automatically to unique packets.

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
3. **Timing:** Zeek's `threshold_elapsed_seconds` is measured using the span of observations already within the sliding window. It is not sensor-to-SIEM latency. ZeekVM and WazuhVM NTP status was unsynchronized; the Wazuh ingestion difference must not be treated as latency evidence.
4. **Attack attribution:** spoofed source is visible as an IP header field, not the proven originator. No automatic source quarantine should be attached to these alerts.
5. **System impact:** alerting does not prove an actual denial-of-service outage on ServerDB. CPU/RSS measurements cover a temporary Zeek process, not just the incremental detector.
6. **Publication scope:** complete PCAPs and full raw logs remain outside Git. This note preserves reproducible commands through the test harness, which requires the locally held PCAPs.

## Suggested next measurements

After NTP is fixed on both VMs, repeat the end-to-end trials with synchronized time and several repetitions to report median and spread of ingestion latency. Separately collect representative quiet/busy baselines across monitored targets, adjust the threshold according to observed mirror topology, and run controlled high-load repetitions with aligned resource samples.

## Artifacts

- Detector and regression harness: [`../blue-team/zeek/site/custom_scripts/icmp_flood/`](../blue-team/zeek/site/custom_scripts/icmp_flood/README.md)
- Wazuh rule: [`../blue-team/wazuh/rules/008_zeek_icmp_flood_rules.xml`](../blue-team/wazuh/rules/008_zeek_icmp_flood_rules.xml)
- Evidence matrix: [`../evidence/icmp-flood/results.tsv`](../evidence/icmp-flood/results.tsv)
