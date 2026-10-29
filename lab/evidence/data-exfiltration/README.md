# Data Exfiltration — reduced post-migration evidence

This folder includes **only synthesized summaries transcribed from the actual terminal results** of the 28 October 2026 regression and no full traffic captures or raw archives.

- [`post-migration-validation-2026-10.tsv`](post-migration-validation-2026-10.tsv): T01–T10 controlled test outcomes. The ten PASS statuses refer to the final Zeek/Wazuh schema after migration.
- [`t09-restart-check.tsv`](t09-restart-check.tsv): original and restarted process identifiers plus the rotation marker reported by T09. These identifiers are ephemeral to this lab run.
- [`README.md`](README.md): evidence scope and limitations.

**Provenance:** T01–T06 from `run.sh full` (2026-10-28 16:59–17:32 UTC), T07 from the warm-up-fixed `extended_run.sh t07` (21:53–22:11 UTC), T08 from `t08-train.sh` followed by `extended_run.sh t08` (22:15–23:15 UTC), T09 from its `t09-pre` and `t09-post` checkpoint (23:20–23:29 UTC), and T10 from `extended_run.sh t10` (17:55–18:25 UTC). These are timestamps printed by the validation tools, with UTC `Z` labels. The original terminal traces and results directories are retained outside the public repository.

This evidence supports controlled **functional detection/correlation** only. A PASS does not establish production-wide performance, exfiltration of sensitive content, host process attribution, or real attacker identity.

Do not commit `results/` wholesale, raw `data_exfiltration.log`, `alerts.json`, PCAP, test payloads, passwords or SSH keys. Rule `111946` matches same source across three Slow candidates; the three distinct destination IPs in T10 were guaranteed by the test input, not by an additional destination-uniqueness constraint in the XML rule.
