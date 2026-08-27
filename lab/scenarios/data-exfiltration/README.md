# Data-Exfiltration Detection

## Objective

Validate the custom Zeek behavioral detection used to identify unusually large outbound data transfers from monitored internal hosts.

The scenario is designed to verify that:

- Zeek learns a traffic baseline for each observed internal source host;
- a dynamic threshold is calculated after the learning period;
- outbound traffic above that threshold generates a custom Zeek event;
- Wazuh ingests the event and produces the expected alert;
- the result is interpreted together with destination, host role, and endpoint evidence.

This scenario demonstrates anomaly detection. A threshold violation is an indicator that requires investigation; it is not proof that confidential data was stolen.

## Components

| Component | Role |
|---|---|
| ClientVM | Monitored internal source host |
| Authorized external test endpoint | Receives controlled outbound test traffic |
| Proxmox OVS mirror | Copies relevant traffic to ZeekVM |
| ZeekVM | Measures outbound TCP payload volume and writes the custom log |
| Wazuh Agent on ZeekVM | Forwards the custom JSON log |
| Wazuh Manager | Applies rules `100913` and `100914` |

## Related files

```text
blue-team/zeek/site/custom_scripts/data_exfiltration/data_exfiltration.zeek
blue-team/wazuh/rules/002_zeek_rules_custom.xml
blue-team/wazuh/agent-configs/zeek-agent-ossec.conf
blue-team/wazuh/integrations/zeek-custom-logs.md
evidence/data-exfiltration/
```

## Detection model

The script analyzes TCP payload sent from an internal source to a destination outside the configured internal subnets.

The current laboratory configuration treats the following networks as internal:

```text
10.3.10.0/24
10.3.20.0/24
10.3.30.0/24
```

Traffic is counted only when:

- the packet is sent by the connection originator;
- the TCP packet contains payload;
- the source belongs to one of the internal networks;
- the destination does not belong to an internal network.

Internal-to-internal traffic, response-direction traffic, and packets without payload are not included in the calculated outbound total.

## Baseline configuration

The current test-oriented values are:

| Parameter | Value | Purpose |
|---|---:|---|
| Calculation window | 1 minute | Aggregates outbound payload for each source host |
| Baseline duration | 5 minutes | Minimum learning period before detection |
| Minimum baseline windows | 5 | Requires multiple non-empty observations |
| Standard-deviation factor | 3.0 | Builds the statistical threshold |
| Maximum safety factor | 1.2 | Ensures the threshold is above the largest baseline window |

The dynamic threshold is calculated as:

```text
dynamic_threshold = max(
    baseline_mean + 3.0 * baseline_standard_deviation,
    baseline_maximum * 1.2
)
```

The state is maintained in Zeek memory. Restarting or redeploying Zeek resets the learned baseline.

## Collected metrics

For each monitored source host and calculation window, the custom log can include:

| Field | Meaning |
|---|---|
| `event_type` | `baseline_completed` or `possible_data_exfiltration` |
| `src_ip` | Monitored internal source |
| `dest_ip` | Main destination for the current window |
| `dest_port` | Port of the main destination |
| `dest_proto` | Transport protocol associated with the destination port |
| `top_dest_bytes` | Bytes sent to the main destination |
| `total_orig_bytes` | Total outbound TCP payload bytes in the window |
| `packet_count` | Number of counted payload-bearing packets |
| `avg_payload_bytes` | Average counted payload length |
| `max_payload_bytes` | Largest counted payload length |
| `baseline_avg_bytes` | Mean outbound bytes during learning |
| `baseline_stddev_bytes` | Baseline standard deviation |
| `baseline_max_bytes` | Largest baseline window |
| `dynamic_threshold` | Calculated detection threshold |
| `window_interval` | Aggregation interval |
| `note` | Human-readable event context |

The `dest_ip`, `dest_port`, and `top_dest_bytes` fields identify the destination that received the most bytes during the window. They do not prove that it was the only destination contacted.

## Custom Zeek log

The script writes JSON records to:

```text
/var/log/zeek-custom/data_exfiltration.log
```

Two event types are relevant.

### Baseline completion

```text
event_type = baseline_completed
```

This event indicates that the script collected enough baseline windows and calculated the dynamic threshold.

For this event, destination fields are deliberately reset because baseline completion does not represent a suspicious connection to a specific destination.

### Possible data exfiltration

```text
event_type = possible_data_exfiltration
```

This event is generated when:

```text
total_orig_bytes >= dynamic_threshold
```

It records the total outbound volume and the main destination observed during that window.

## Wazuh rules

The custom events are processed by:

```text
blue-team/wazuh/rules/002_zeek_rules_custom.xml
```

| Rule ID | Level | Event | Meaning |
|---:|---:|---|---|
| `100913` | 3 | `baseline_completed` | Baseline and dynamic threshold are ready |
| `100914` | 8 | `possible_data_exfiltration` | Outbound bytes exceeded the dynamic threshold |

Rule `100913` is operational information. Rule `100914` is a suspicious behavioral alert that requires contextual validation.

The current ruleset does not correlate the data-exfiltration alert with Auditd file reads, FIM events, process telemetry, or an automated containment action.

## Controlled validation procedure

### 1. Verify the script is loaded

On ZeekVM:

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl deploy
```

Confirm that the custom script is loaded through the site configuration.

### 2. Observe the custom log

```bash
sudo tail -f /var/log/zeek-custom/data_exfiltration.log
```

### 3. Generate representative baseline traffic

From ClientVM, generate ordinary authorized outbound activity for at least five minutes.

The learning traffic should:

- be representative of the host's normal behavior;
- produce payload-bearing TCP traffic in at least five one-minute windows;
- avoid an unusually large transfer during baseline creation;
- traverse the mirrored path observed by ZeekVM.

### 4. Confirm baseline completion

Expected Zeek event:

```text
baseline_completed
```

Expected Wazuh rule:

```text
100913
```

Record the calculated values:

- `baseline_avg_bytes`;
- `baseline_stddev_bytes`;
- `baseline_max_bytes`;
- `dynamic_threshold`.

### 5. Generate a controlled high-volume transfer

Send a benign test file or generated test data from ClientVM to an authorized external laboratory endpoint.

The transfer should be large enough that the outbound TCP payload observed in one calculation window exceeds the learned threshold.

Do not use real confidential information. Do not send data to an unauthorized external service.

### 6. Confirm the alert

Expected Zeek event:

```text
possible_data_exfiltration
```

Expected Wazuh rule:

```text
100914
```

Verify that the event contains:

- the correct `src_ip`;
- the expected main destination and port;
- `total_orig_bytes` above `dynamic_threshold`;
- a plausible packet count and payload statistics.

### 7. Validate Wazuh ingestion

On the Wazuh Manager, review the alert stream or use the dashboard to confirm that rule `100914` was generated from the Zeek agent.

The source log path must match:

```text
/var/log/zeek-custom/data_exfiltration.log
```

## Expected flow

```text
Normal outbound traffic
        |
        v
Five or more baseline windows
        |
        v
Dynamic threshold calculated
        |
        +--> Zeek baseline_completed
        +--> Wazuh rule 100913
        |
        v
Controlled high-volume outbound transfer
        |
        v
Window total exceeds threshold
        |
        +--> Zeek possible_data_exfiltration
        +--> Wazuh rule 100914
```

## Evidence to preserve

A reduced evidence set should include:

- one sanitized `baseline_completed` JSON record;
- one sanitized `possible_data_exfiltration` JSON record;
- the matching Wazuh alert for rule `100913`;
- the matching Wazuh alert for rule `100914`;
- the source and destination roles;
- the test timestamp;
- the calculated threshold and observed window total;
- a short explanation of why the test traffic was authorized.

Store publication-safe artifacts under:

```text
evidence/data-exfiltration/
```

Do not publish the transferred test file, complete PCAPs, full logs, credentials, or unrelated traffic.

## Result interpretation

A `possible_data_exfiltration` alert means that the monitored source produced more outbound TCP payload than expected from its learned baseline.

Investigation should consider:

- whether the destination is approved;
- whether the host normally performs backups or software distribution;
- whether the transfer was user initiated;
- which process created the connection;
- whether sensitive files were accessed immediately before the transfer;
- whether FIM or Auditd recorded related file activity;
- whether the traffic pattern was a single burst or repeated over time.

## False positives

Potential legitimate causes include:

- backups;
- package or image uploads;
- cloud synchronization;
- large software updates sent by an internal service;
- administrative file transfers;
- workload changes after the baseline was created;
- an unrepresentative or excessively quiet learning period.

## Limitations

- The detector measures TCP payload volume, not semantic file content.
- The measured byte total is not guaranteed to equal the original file size.
- Encrypted traffic remains encrypted; the detector relies on metadata and volume.
- UDP transfers are not counted by the current `tcp_packet` implementation.
- Low-and-slow exfiltration may remain below the threshold.
- A short test baseline may not represent normal long-term behavior.
- Restarting Zeek clears the in-memory baseline.
- The main destination field represents the largest destination in the window, not necessarily the only one.
- The current Wazuh rule does not automatically identify the responsible endpoint process.
- The current repository does not attach an Active Response to rule `100914`.

## Cleanup

After the controlled test:

- stop the generated traffic;
- remove temporary test data from both endpoints;
- retain only sanitized evidence;
- verify that no real sensitive data was used;
- restore the intended baseline state if the test traffic distorted it;
- restart or redeploy Zeek only when intentionally resetting the learned baseline.

## Future improvements

- Correlate rule `100914` with Auditd file-read events from sensitive directories.
- Add process and socket attribution through endpoint telemetry.
- Add destination reputation and allowlist context.
- Persist or periodically rebuild baselines safely.
- Support separate baselines by protocol, destination class, or time of day.
- Detect repeated low-volume transfers across multiple windows.
- Add a high-confidence correlation rule before enabling automatic containment.
