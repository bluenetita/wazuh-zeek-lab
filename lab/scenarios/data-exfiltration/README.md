# Data Exfiltration — adaptive and low-and-slow detection

**Status:** validated in the isolated Proxmox cyber range on 28 October 2026 (10/10 controlled tests, after the final detector migration). **Mode:** detection only; no scenario-specific Active Response.

## Objective and observation model

Detect unusual TCP outbound volumes from internal hosts to the simulated external network. Traffic from the Client Linux VMs to an authorized Kali test receiver was mirrored by Open vSwitch to Zeek, written as JSON into a single custom log, selected by the Zeek Wazuh Agent, and classified/correlated by native Wazuh XML rules.

```text
Client Linux (authorized synthetic sender)
  -> RouterOS / pfSense -> authorized Kali receiver
                | OVS mirror VLAN 999
                v
         Zeek VM (completed TCP flows)
                |
   /var/log/zeek-custom/data_exfiltration.log
                |
      Wazuh Agent (JSON + restrict)
                |
      Wazuh Manager (XML rules 111940–111948)
                v
      Alerts and temporal correlations
```

The network detector estimates **originator-to-responder payload bytes from completed TCP connection sequence information**. These figures are not the same as confirmed receiver-side bytes, raw mirrored packet counts, application files, or proof of actual theft. Receiver-side byte counts were checked separately by the controlled test suite.

### Components and files

| Component | Versioned path |
|---|---|
| Zeek loader/configuration | `blue-team/zeek/site/local.zeek` and `site/custom_scripts/data_exfiltration/` |
| Wazuh Zeek agent | `blue-team/wazuh/agent-configs/zeek-agent-ossec.conf` |
| Wazuh XML base and correlation | `blue-team/wazuh/rules/002_zeek_rules_custom.xml`, `097_zeek_exfil_rules.xml`, `098_zeek_exfil_slow_persistence_rules.xml` |
| Reduced results | `evidence/data-exfiltration/post-migration-validation-2026-10.tsv` |
| Detailed results and reproducibility | `docs/data-exfiltration-validation-2026-10.md` |

All paths in the table are relative to the repository root.

## Detection logic

### Completed-flow data and windows

The `DataExfilFlow` module accepts relevant outbound TCP flows from the configured internal networks (`10.3.10.0/24`, `10.3.20.0/24`, `10.3.30.0/24`). `DataExfilWindow` maintains a **60-second window** and differentiates destination and host aggregation. Quality checks (e.g., incomplete first window, capture gaps, non-finalized/unsuitable connections) prevent ineligible windows from producing Adaptive candidates. A destination and the host can each generate a decision: do not treat them as two distinct exfiltration events.

The first observed window for a new source can be intentionally marked `first_window_partial=true`, producing `window_not_eligible`. A benign warm-up and a completed window were needed to fairly test the second client in T07.

### Adaptive: single large transfer

- When there is no established baseline, the starting candidate threshold is **4 MiB**.
- A ready baseline requires **30 confirmed eligible benign samples** per profile; the history is bounded to 60 entries.
- Delayed learning confirmation is **15 minutes**; suspicious candidates suspend learning for **10 minutes**. Training samples are capped at 2 MiB.
- The configured minimum ready-state candidate threshold is **1 MiB**, but the computed threshold may be higher depending on the learned median and 90th percentile.
- The validated T08 Host baseline became `ready` after 43 controlled 256-KiB transfers, with 30 confirmed samples and a threshold of 1,048,576 bytes.

The decision event is `exfil_adaptive_decision` with `scope=destination` or `scope=host`, `adaptive_candidate`, `sample_bytes`, `threshold_bytes`, `sample_eligible`, `profile_state`, and an explanatory `reason`.

### Slow: repeated smaller transfers

A candidate is based on **ten completed one-minute rolling windows**, with at least **eight active windows**, a rolling volume of **at least 4 MiB**, and a per-window ceiling **below 1 MiB**. The implementation also checks inter-window continuity and time-span constraints; see the actual `slow.zeek` source for all criteria.

The decision event is `exfil_slow_window_decision`, with `slow_candidate`, `candidate_active`, `rolling_active_windows`, `rolling_payload_bytes`, `rolling_threshold_bytes`, `reason`, and scope fields. A continuation can describe a still-active rolling candidate **without new bytes** in the current window. Wazuh therefore distinguishes candidate detection from persistence of its state.

### Wazuh classification and correlation (native XML)

| Rule | Meaning | Level |
|---|---|---:|
| `111940` | Parent selector for the consolidated Zeek event stream | 0 |
| `111941` | Adaptive: destination candidate | 8 |
| `111942` | Adaptive: host aggregate candidate | 5 |
| `111943` | Slow: destination candidate | 9 |
| `111944` | Slow: host aggregate candidate | 5 |
| `111945` | Repeated Adaptive destination candidates, same `src_ip`, 2 within 600 s | 10 |
| `111946` | Repeated Slow destination candidates, same `src_ip`, 3 within 900 s | 11 |
| `111947` | Internal suppressed Slow continuation; `no_log`, used for correlation | 1 |
| `111948` | Two Slow continuation events for the same `src_ip` within 240 s | 9 |

`111945` and `111946` correlate by **source IP**, not necessarily the same destination; `111946` does not itself enforce three distinct destination IPs, although T10 tested precisely that traffic pattern. `111948` reports persistence of candidate state, not independently confirmed new exfiltration; the destination in its alert is the **latest** observed destination, not a per-destination correlation key.

The Wazuh Agent forwards candidate decisions and selected destination continuation events using its JSON `<localfile>` and PCRE2 restrictions. Regular Zeek diagnostics are retained locally but not all forwarded to the manager. This scenario deliberately does **not** introduce a Python correlator or enable RouterOS quarantine.

## Validation, 28 October 2026

| Test | Validation | Result |
|---|---|---|
| T01 | 5-MiB burst; Adaptive Destination and Host | PASS |
| T02 | Repeated Adaptive candidate; `111945` | PASS |
| T03 | Twelve 450-KiB transfers; Slow Destination/Host; two continuation states and `111948` | PASS |
| T04 | Controlled Slow candidate closure | PASS |
| T05 | Benign 100-KiB transfer, no Wazuh alert | PASS |
| T06 | 3 + 3 MiB toward two receivers, Host aggregate detected | PASS |
| T07 | Independent source hosts A/B; no accidental cross-source `111945` correlation; B-B positive | PASS |
| T08 | Host baseline ready after 30 confirmed samples, 256 KiB negative / 5 MiB positive, `111942` | PASS |
| T09 | Log rotation + Zeek and agent restarts; detection recovered after benign warm-up | PASS |
| T10 | Three distinct receiver IPs, fresh Slow candidates; `111946` | PASS |

These are **functional controlled-case passes**, not measurements of false-positive/false-negative rates across natural workloads, and not an estimated sensitivity of a production detector. The test runner uses authorized synthetic traffic only. Earlier pre-migration results are kept separately and must not be mixed with this report.

## Operational verification

On ZeekVM, verify script compilation and collector configuration:

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl status
sudo /var/ossec/bin/wazuh-logcollector -t
sudo tail -n 10 /var/log/zeek-custom/data_exfiltration.log
```

On Wazuh Manager, validate the XML rules:

```bash
sudo /var/ossec/bin/wazuh-analysisd -t
```

`zeekctl deploy`/restart resets in-memory Adaptive and Slow state; subsequent tests must warm up the first window. The custom Zeek log is rotated with the shared `/etc/logrotate.d/zeek-custom` policy (using `copytruncate` in the validated lab). The agent monitors only future events for this stream.

## Scope and limitations

- Inferred TCP outbound bytes from **finalized connections**, not confirmed loss of confidential information, and not direct observation of process/file activity.
- No UDP exfiltration detector, data-content inspection, or payload/decryption feature is claimed.
- Potential false positives include authorized backups, software distribution, and cloud sync; training represents only the lab traffic and must be recalibrated for other environments.
- Host-level aggregation and rolling windows can merge evidence across different destinations; review source, destination, time, and `reason` together.
- The separate Auditd/AppArmor endpoint sources present in this repository are **not** used by these exfiltration-specific Wazuh XML correlations. No automated containment is triggered by this scenario.
- Full raw logs, test payloads, snapshots and credentials are deliberately excluded from public version control.

## Release notes

The [October 2026 final publication notes](../../docs/data-exfiltration-release-notes-2026-10.md) describe the active file set and why the legacy packet-based source should be removed from the repository.
