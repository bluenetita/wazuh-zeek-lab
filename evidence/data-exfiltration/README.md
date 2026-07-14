# Data-Exfiltration Evidence

This directory is reserved for reduced and sanitized artifacts produced during the controlled data-exfiltration validation scenario.

## Related scenario

```text
scenarios/data-exfiltration/README.md
```

## Recommended artifacts

A useful evidence set can include:

```text
baseline-completed-sample.json
possible-data-exfiltration-sample.json
wazuh-rule-100913-sample.json
wazuh-rule-100914-sample.json
```

Only add files that were actually produced during a validated test.

## Minimum fields

### Baseline evidence

Preserve fields such as:

- `event_type`;
- `src_ip`;
- `baseline_avg_bytes`;
- `baseline_stddev_bytes`;
- `baseline_max_bytes`;
- `dynamic_threshold`;
- `window_interval`.

### Detection evidence

Preserve fields such as:

- `event_type`;
- `src_ip`;
- `dest_ip`;
- `dest_port`;
- `dest_proto`;
- `top_dest_bytes`;
- `total_orig_bytes`;
- `packet_count`;
- `dynamic_threshold`;
- Wazuh rule ID and level.

## What the evidence demonstrates

The evidence should show that:

1. Zeek completed the baseline for the monitored host;
2. a later outbound window exceeded the calculated threshold;
3. the custom Zeek JSON log was generated;
4. Wazuh matched rule `100914`;
5. the source and destination roles were consistent with the controlled test.

## Sanitization

Replace real or unnecessary values with documented placeholders where required.

Do not commit:

- the transferred file;
- confidential or personal data;
- complete Zeek logs;
- complete Wazuh alert archives;
- PCAP files containing unrelated traffic;
- credentials or tokens;
- public service identifiers that are not needed to explain the result.

Each evidence file should be accompanied by enough context to explain the test date, the authorized source and destination roles, and what the selected fields prove.
