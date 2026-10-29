# Data Exfiltration — final migration and controlled validation, October 2026

## Experimental objective

Demonstrate end-to-end classification of both one-off abnormal TCP outbound transfers (Adaptive) and repeated smaller transfers (Slow), using Zeek completed-flow estimates and **native Wazuh XML correlation**, without Active Response. This report reflects only the **post-migration** schema and tests completed on **28 October 2026**.

## Architecture and migration

The former single `data_exfiltration.zeek` packet-based script, its `baseline_completed`/`possible_data_exfiltration` events, and Wazuh rules `100913/100914` were retired from the active configuration. The final Zeek package uses modules `DataExfilFlow`, `DataExfilWindow`, `DataExfilAdaptive`, and `DataExfilSlow`, loaded by the consolidated `__load__.zeek`. The event families are `exfil_adaptive_decision` and `exfil_slow_window_decision`, logged in **one** `data_exfiltration.log` file.

Wazuh Agent receives the JSON stream and forwards only selected candidate decisions/continuations using PCRE2 `<restrict>`. Wazuh Manager evaluates the custom rules `111940–111948` in XML. No Python correlator or scenario-specific RouterOS Active Response was introduced.

The migration was run under an operational stop/start sequence, with service configuration checks (`zeekctl check`, `wazuh-logcollector -t`, `wazuh-analysisd -t`), VM snapshots, and rollback backups kept outside Git. The regression below was run **after** the migration.

## Observed evidence (test log excerpts summarized)

| ID | Controlled scenario | Outcome / evidence |
|---|---|---|
| T01 | 5 MiB single transfer | Adaptive destination and host decisions received in Wazuh; PASS |
| T02 | second 5 MiB transfer | repeated candidate correlation `111945` observed; PASS |
| T03 | 12 × 450 KiB, roughly one per minute | Slow destination and host candidate; 10 active rolling windows, two Destination continuation entries, one `111948` persistence alert; PASS |
| T04 | stop Slow transfers and observe inactivity | destination candidate closure observed; PASS |
| T05 | 100 KiB benign transfer | receiver acknowledged 102,400 bytes, Zeek window observed, no Wazuh alert; PASS |
| T06 | 3 MiB + 3 MiB to two IPs | 6 MiB receiver-side total, host aggregation detected; PASS |
| T07 | two source clients and A–B–B Adaptive sequence | after benign 256 KiB warm-up for A and B, `111945` fired only after second B candidate; PASS |
| T08 | baseline learning and threshold contrasts | 43 benign 256-KiB training transfers yielded 30 confirmed Host samples; `ready`; threshold 1,048,576 bytes; 256 KiB below threshold no alert; 5 MiB above generated `111942`; PASS |
| T09 | rotate custom log, restart Zeek and Wazuh Agent | `rotation_changed=1`, PIDs changed, initial windows warmed up, Zeek destination and host candidates matched `111941`/`111942`; PASS |
| T10 | three distinct external receiver IPs, controlled Slow transfers | three fresh Destination candidates forwarded, one source-correlated `111946`; PASS |

**T07 diagnostic:** the first initial run was `INCONCLUSIVE` only because Client B's first window reported `first_window_partial=true`, `baseline_sample_eligible=false`, `capture_gap_flows=0`, `non_sf_flows=0`, and `missing_outbound_byte_estimates=0`. The warm-up-fixed rerun passed; no detector thresholds or Manager rules were changed.

**T08 learning:** `ready` means 30 *confirmed* eligible samples after a 15-minute delayed confirmation and a candidate-related learning quarantine; merely sending 30 packets/transfers without valid windows would not be sufficient. Only the Host-scope negative/positive threshold test is claimed as fully exercised by T08. After the subsequent T09 restart the baseline was reset (expected), so T08 evidence must be kept from before that restart.

**T09 restart state:** Zeek PID `1024083` became `1040586`; Wazuh Logcollector PID `1024180` became `1040940`. The T09 report explicitly shows one post-restart `111941`, one `111942`, and zero `111945` (the final test required only a single suspicious event).

## Rule semantics and correlation caveats

- `111941`/`111942`: Adaptive destination/host events are two views of a candidate window.
- `111943`/`111944`: Slow destination/host views are similarly not guaranteed distinct episodes.
- `111945`: source-scoped repeated Adaptive destination candidates within 600 seconds.
- `111946`: source-scoped repeated Slow destination candidates within 900 seconds; **distinct destinations are not enforced by this XML** (T10 explicitly generated distinct destination traffic).
- `111947`/`111948`: persistence of an active Slow rolling candidate via suppressed continuation events; these do not prove additional bytes in each continuation window, and `111948` uses `src_ip`, not `dest_ip`, for correlation.

## Measurement limits

Zeek's byte figures use sequence-derived payload estimates for completed TCP connections. These are different from independently verified bytes written to the receiver. Zeek does not directly determine file contents, endpoint process identity, actual theft, or the identity of an attacker. A lab PASS validates these selected test cases, not general statistical performance or false-positive rates on natural traffic.

The first observation window and post-restart warm-up matter. The rolling and Adaptive learning state is in memory, and a Zeek deploy can reset it. `only-future-events=yes` limits replay by the Zeek Wazuh Agent for the custom log stream. Other Active Response scripts retained elsewhere in the repository are not enabled by this detection scenario.

## Reproducing and preserving evidence

Use an isolated lab and only synthetic authorized test data. Verify mirroring and synchronization; baseline state and rule history must be isolated between tests; collect the Zeek JSON records, Wazuh alerts, and receiver-side counts. Compare source/destination, `scope`, `reason`, `sample_eligible`, profile state, correlation timeframe and rule IDs. Preserve the original full result directory privately and publish only reduced metrics as `evidence/data-exfiltration/` summaries.

After modifying the Zeek site scripts or Wazuh rules, validate with `zeekctl check`, `wazuh-logcollector -t`, and `wazuh-analysisd -t`. Check that no legacy `data_exfiltration.zeek`, `exfil_shadow_*` or `100913/100914` rules remain loaded. Keep VM snapshots/rollback backups out of Git.
