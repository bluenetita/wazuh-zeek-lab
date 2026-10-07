# AppArmor: servicefix series, 5 complain/enforce pairs

The `t0_utc` timestamps range from **October 1, 2026, 23:08:58.900Z** to **October 1, 2026, 23:15:12.127Z**. The campaign name contains `20261002`, but the original UTC timestamps have not been rewritten.

## Results verified from each run's files

| Condition | Runs | Decision for `/usr/bin/dash` exec | SYSCALL with same audit ID | Service active before/after | Main PID unchanged | Health-check rc=0 before/after |
|---|---:|---|---|---:|---:|---:|
| complain | 5 | ALLOWED, 5/5 | success=yes, exit=0, 5/5 | 5/5 | 5/5 | 5/5 |
| enforce | 5 | DENIED, 5/5 | success=no, exit=-13, 5/5 | 5/5 | 5/5 | 5/5 |

All 5 enforce runs also contain a Wazuh `130920` alert corresponding to the selected audit ID. The two conditions are kept separate and paired through `AA-SVCFIX-P01` ... `AA-SVCFIX-P05`. The comparison concerns the observed operation; it is not a general effectiveness percentage against arbitrary attacks.

## Included data

- [Original table](apparmor_runs.original.tsv): copy of the campaign matrix.
- [Verified rows](verified_runs.jsonl): values extracted from runtime files for each run.
- [Selected AVC and SYSCALL records](selected_audit_events.log): only the relevant AppArmor event and the syscall sharing the same audit identifier.
- [Reduced Wazuh alerts](selected_wazuh_alerts.jsonl): projections of rule `130920` alerts, not a complete alert export.
- [Unit snapshot](inventario-terminale.service.snapshot.txt).

The original matrix contains `service_active_before/after=[SSH password prompt]`. This is field contamination introduced during collection, **not** the actual systemd state. The corresponding `service_active_*.txt` files contain `active`, while `main_pid_*.txt` allows the PID comparison. Corrected values are published in the derived file without silently modifying the original matrix.

The original `syscall_result=not_independently_measured` column and the note `independent_outcome_check=not_configured` are preserved. The audit SYSCALL records already present in the evidence allow verification of the system-call result; they do not replace an additional independent application-level test. For `AA-C-SVCFIX-03`, the AVC and SYSCALL records are present in `audit_after_marker_poll.txt`, not in `audit_after_marker_full.log`; the derived file records this difference.

## What the availability check measures

The configured command was `systemctl is-active --quiet inventario-terminale.service` followed by a TCP connection to `127.0.0.1:80` with a 2-second timeout. Therefore, the result confirms **an active service and a reachable local port**; it does not certify successful execution of a full inventory-menu transaction. Main PID continuity is verified at the two collected timestamps, not through continuous monitoring.

## Relationship with source code and profile

The [inventory source code](../../../infrastructure/server-db/inventario-service/inventario.c) and the included AppArmor profile represent the components of the documented scenario. The final tests show the complain/enforce behavior summarized above.

The [previous series](../2026-10-01-baseline/README.md) is not aggregated with this one because its before/after PIDs differ. Use the servicefix series when describing process continuity observed in the final tests.
