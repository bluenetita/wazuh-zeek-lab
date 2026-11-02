# Adaptive Data Exfiltration Detection - reduced evaluation datasets

This directory contains only aggregate or scripted-case tables prepared from the consolidated experimental evaluation, **not** unredacted traffic captures or full Wazuh alert logs. It is intended for responsible publication after an organizational disclosure review.

- [`live_trial_summary.csv`](live_trial_summary.csv): P01-P06 live sender/receiver/Zeek counts, detector candidates and limited Wazuh rule counts. Read the `quality` and `limitations` columns before quoting numbers.
- [`paired_off_on_cases.csv`](paired_off_on_cases.csv): original 35 case-pair analytical rows from the offline paired evaluation; deterministic seeds and workload labels, without host IPs or payloads.
- [`profile_summary.csv`](profile_summary.csv): per-profile aggregate OFF/ON thresholds and later probe comparisons.

See the [study description and figure](../../../docs/research/adaptive-data-exfiltration/README.md), including the audit attribution (original source files vs operator stdout) and limits of inference.

**Do not publish:** complete `alerts.json`, Wazuh original alert IDs, raw PCAPs, sender/receiver logs, HTTP payloads, VM snapshots, credentials, SSH material, or private test runner configs. The operator-reported `431/431` verification refers to the *private* original manifest and operator-run hash check; this folder does not contain 431 original files.

**Internal traceability:** the live series is identified in private artifacts as `LG07-L`; the offline paired series as `LG07-P`. File contents remain unchanged from the frozen reduced analytic export.
