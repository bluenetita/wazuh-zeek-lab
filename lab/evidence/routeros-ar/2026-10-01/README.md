# Reverse shell and RouterOS Active Response: 5 OFF + 5 ON

Campaign performed on **October 1, 2026**. Runs `RS-OFF-01` ... `RS-OFF-05` and `RS-ON-01` ... `RS-ON-05` retain their original names, UIDs, and timestamps.

| Condition | Runs | Live + movement + eligible alert | AR invocation recorded | Quarantine observed | Expected probe failure |
|---|---:|---:|---:|---:|---:|
| OFF | 5 | 5/5 | 0/5 | 0/5 | 0/5 |
| ON | 5 | 5/5 | 5/5 | 5/5 | 5/5 |

The probe runs **from client `10.3.20.2` to `10.2.0.2` on TCP/22**, with a 0.5-second timeout and a configured 0.50-second interval. It is not a probe from the Manager to a port on the client. The baseline requires 2 confirmations and the blocked state requires 2 confirmations. `contained_utc` records the first failure in the sequence used by the summary.

## Descriptive timing: preserve the meaning of each measurement

| Campaign field | Definition | n | Mean | Median | Min-max |
|---|---|---:|---:|---:|---:|
| T_D | coordinator t0 -> eligible Wazuh alert | 10 | 33.2141 s | 32.9225 s | 31.938-35.925 s |
| T_AR, ON | Wazuh alert -> local routeros_quarantine log line | 5 | 0.3578 s | 0.359 s | 0.341-0.372 s |
| T_C, ON | coordinator t0 -> first recorded probe failure | 5 | 36.744 s | 36.868 s | 36.269-37.017 s |

The calculations in [metrics.json](metrics.json) reproduce the [original summary](metrics_summary.original.txt). **These are not universal containment times.** T_D includes human latency between GO and trigger. T_AR uses timestamps from the same Wazuh host but identifies the script completion log line rather than the first blocked packet. T_C combines coordinator and client clocks, polling, and timeout; the snapshots indicate unsynchronized clocks. Do not subtract these values to derive precise cross-host latencies.

Probe failure, Quarantine membership, and the script message are complementary evidence. They do not demonstrate isolation of **all** protocols or independently verify closure of the specific reverse-shell TCP/4444 session. The OFF result means no block was observed **during the observation interval**, not an estimated infinite containment time.

## Reduced evidence

- [Original matrix](routeros_ar_runs.original.tsv) and [per-run verification](verified_runs.jsonl).
- [Selected Wazuh alerts by UID](selected_wazuh_alerts.jsonl) and [Zeek records](selected_zeek_events.jsonl).
- [Active Response messages](active_response_events.jsonl) and [Quarantine before/after](quarantine.snapshots.txt).
- [Firewall counters](firewall-counters.snapshots.txt) and [policy listing](firewall-policy.snapshot.txt).
- Complete probe series containing only valid timestamp/rc rows in `probes/RS-OFF-01.tsv` ... `probes/RS-ON-05.tsv`.
- [Coordinator cleanup](coordinator-cleanup.log): evidence of explicit quarantine removal.

The firewall listing documents the observed order, with FastTrack/established rules before the Quarantine drops in the historical snapshot. It is a **diagnostic snapshot**, not an importable `.rsc` export or a proposed production policy. Counter values are snapshots and cannot be uniquely attributed to individual sessions.

The probe becomes reachable again in ON runs after cleanup because the campaign explicitly removes the address from the list. This **does not demonstrate autonomous rollback** by `routeros_quarantine.py`.

The distributed Manager configuration keeps the action commented out.
