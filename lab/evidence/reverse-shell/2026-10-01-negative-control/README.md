# Reverse-shell correlation negative control

The [original matrix](correlation_negative_runs.original.tsv) describes a single `CORR-NEG-01` control, `multi_host_same_target`, with precursors present on different hosts, shared target `10.2.0.2:22`, a 90-second window, and `forbidden_count=0`. The campaign-reported result is `VALID_PASS`.

The same matrix classifies the control as synthetic/benign, and trigger details are not included. It is not a new replication of a real attack, it is not the October 6 SSH A1->V1 + A2->V2 test, and by itself it does not demonstrate general robustness under concurrency. The ten real reverse-shell OFF/ON runs are documented under [RouterOS AR](../../routeros-ar/2026-10-01/README.md).
