# AppArmor: pre-servicefix series

The [original matrix](apparmor_runs.original.tsv) contains 5 complain/enforce pairs. The [selected events](selected_audit_events.log) confirm ALLOWED in 5/5 complain runs and DENIED in 5/5 enforce runs. The [verified runtime data](verified_runs.jsonl), however, show a **different Main PID before and after in all 10 runs**.

The service was `active` at both checks and the TCP availability check returned `rc=0`, but this does not demonstrate the absence of restarts. The cause of the PID change must not be inferred from only those two observations. The later [servicefix series](../2026-10-servicefix/README.md) instead shows an unchanged PID in 10/10 runs and includes the associated C source.

The two series are published separately and are not aggregated as twenty homogeneous replications.

The [five enforce alerts with rule 130920](selected_wazuh_alerts.jsonl) are selected projections. The original matrix retains the `not_independently_measured` limitations; `verified_runs.jsonl` contains the verified values used in the summary.
