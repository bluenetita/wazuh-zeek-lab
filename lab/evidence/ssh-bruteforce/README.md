# Publishable SSH evidence

This directory deliberately distinguishes **real excerpts**, **terminal summaries**, and **historical samples**. Synthetic results are not presented as laboratory measurements.

| File | Nature |
|---|---|
| [observed-test-summaries.jsonl](observed-test-summaries.jsonl) | 21 rows transcribed from the supplied test terminal output; schema `observed_terminal_projection`, not raw `alerts.json` |
| [zeek-unknown-auth.sample.jsonl](zeek-unknown-auth.sample.jsonl) | Real payload from the 5-session unknown-auth SSH case, UID `CREHcO39s2FsWoXzle` |
| [wazuh-pair-unknown-auth.sample.jsonl](wazuh-pair-unknown-auth.sample.jsonl) | Projection of the real `120939` alert for the same UID |
| [wazuh-scan-pair.sample.jsonl](wazuh-scan-pair.sample.jsonl) | Projection of the real October 5 `120936` alert, UID `CXbu2L8xbX57ez1d1` |
| [legacy-known-auth.sample.jsonl](legacy-known-auth.sample.jsonl) | Two historical events reported in `zeekvm/other.txt`; they do not validate the new fallback |

The real case after 16:34 on October 5 is included in the summaries and is not conflated with the earlier 16:27 `120936` alert. Timestamps are preserved rather than being rewritten to the publication date.

The absence of a rule ID from a query result refers to that queried interval and excerpt; it is not proof of global absence from all logs. Reported negative cases include an observed antecedent and an observed login. Multi-pair tests remain sequential.

The samples do not contain passwords. Laboratory addresses and names are retained so that pairs remain verifiable; they do not represent public infrastructure.

See the [test procedure](../../scenarios/ssh-bruteforce/TESTS.md).
