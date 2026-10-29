# Zeek Log Samples

This directory is reserved for small, sanitized examples of standard and custom Zeek events.

Acceptable examples include one or a few lines from:

- `conn.log`;
- `possible_malware.log`;
- `reverse_shell_live.log`;
- `reverse_shell_movement.log`;
- `reverse_shell_final.log`;
- `data_exfiltration.log`.

Replace real IP addresses, timestamps, UIDs, hashes, filenames, and paths when they are not required to demonstrate the schema.

Do not publish complete logs, packet captures, payloads, credentials, tokens, private keys, or personal data.

## Consolidated Data Exfiltration log

The final JSON stream has `exfil_adaptive_decision` and `exfil_slow_window_decision` records alongside diagnostic window and baseline-audit records. These events are **not** the retired `baseline_completed` or `possible_data_exfiltration` schema. Not every locally logged diagnostic event passes the ZeekVM agent PCRE2 filter into Wazuh.

Use the [Data Exfiltration scenario](../../../scenarios/data-exfiltration/README.md) for supported field meanings. Only publish a minimized synthetic/sanitized JSON example after verifying its schema against the live detector; no fabricated alert logs are included in this update.
