# Troubleshooting

## Zeek receives no traffic

```bash
ip -br link
sudo tcpdump -ni <MIRROR_INTERFACE>
sudo /opt/zeek/bin/zeekctl diag
```

Check VLAN 999, OVS mirroring, interface state, and Zeek `node.cfg`.

## `scanning.log` is missing

```bash
sudo /opt/zeek/bin/zeekctl check
sudo grep -R "custom_scripts/scanning" /opt/zeek/share/zeek/site
sudo journalctl -u zeek -n 100 --no-pager
```

Check the `@load custom_scripts/scanning` line and the permissions on `/var/log/zeek-custom/`.

## A scan test does not trigger

Confirm that the test reaches the threshold inside the configured 60-second window and that the traffic is visible on the mirror. Current defaults are:

| Event | Threshold |
|---|---:|
| `host_scan` | 20 unique ARP targets |
| `port_scan` | 100 unique TCP ports to one target |
| `udp_port_scan` | 50 unique UDP ports to one target |
| `address_scan` | 2 unique targets on one TCP port |
| `icmp_host_scan` | 2 unique ICMP targets |

If testing an older log sample, check whether it uses the historical `scanner_ip` field instead of the current `src_ip` field.

## Wazuh does not ingest `scanning.log`

Verify the ZeekVM agent `<localfile>` entry, JSON format, file permissions, and the agent log:

```bash
sudo tail -n 100 /var/ossec/logs/ossec.log
```

Restart the agent after changing monitored files.

## Scanning rule matches but correlation does not

Confirm that:

- the earlier reverse-shell correlation rule actually triggered;
- the later scan is in group `zeek_scanning`;
- both events expose exactly the same `src_ip` value;
- the scan arrived within the 900-second correlation timeframe;
- the manager is using the expected `005_zeek_scanning_correlation.xml` file.

## AppArmor events do not reach Wazuh

On ServerDB, verify that Auditd/AppArmor events exist and that the agent collects `/var/log/audit/audit.log`. Then inspect the Wazuh Agent log for permission or collection errors.

## AppArmor decoder does not match

Use `wazuh-logtest` with a sanitized real AppArmor audit record. Confirm that the raw event contains an AppArmor decision such as `apparmor="DENIED"` and a supported Audit record type.

## Base AppArmor rule matches but a specialized rule does not

Specialized rules depend on fields such as `apparmor.object_class`, `apparmor.operation`, `apparmor.name`, and `apparmor.denied`. Confirm that the decoder extracted the required field and that the event's mask/operation satisfies the rule.

## AppArmor enforce mode breaks legitimate service behavior

Return to complain mode in the lab, generate only expected service activity, review the Audit/AppArmor events, update the profile minimally, reload it, and retest. Do not enable broad execute/file permissions merely to silence denials.

## Wazuh rule/decoder syntax check

```bash
sudo /var/ossec/bin/wazuh-analysisd -t
sudo /var/ossec/bin/wazuh-logtest
```

## Data Exfiltration: baseline remains in `training`

The final detector learns from **eligible, benign, completed-TCP-flow windows**, rather than from a fixed five-minute packet counter. An Adaptive profile needs **30 confirmed samples**; candidate samples are held for **15 minutes** before promotion and a candidate can suspend learning temporarily. A profile can therefore remain in `training` during apparently successful transfers.

On ZeekVM, examine local JSON diagnostics (only selected candidate events are forwarded to Wazuh):

```bash
sudo sed '$d' /var/log/zeek-custom/data_exfiltration.log | jq -c '
  select(.event_type == "exfil_adaptive_decision" and .scope == "host")
  | {ts,src_ip,profile_state,profile_samples_before,baseline_pending_count,sample_bytes,sample_eligible,adaptive_candidate,reason}
' | tail -n 15
```

For `quality_excluded` or `window_not_eligible`, also inspect the matching `exfil_window_summary` and `exfil_destination_window` records. `first_window_partial=true` on a newly observed source is expected: perform a small authorized warm-up, allow a window to close, and confirm an eligible subsequent window. If `capture_gap_flows`, `non_sf_flows` or `missing_outbound_byte_estimates` are nonzero, investigate the mirror/capture and TCP completion before trusting the measurement. Do **not** bypass quality gates to force an alert.

A Zeek restart/deploy resets in-memory training and Slow rolling state. Historical T08 evidence is from before the T09 restart; a new `ready` state must be learned afresh after restart.

## Data Exfiltration: no Wazuh alert despite a local Zeek event

Check the complete pipeline before changing thresholds:

1. Verify Zeek has logged an **eligible candidate**, not merely a diagnostic window or a large but quality-excluded sample.
2. Confirm the ZeekVM agent has exactly one JSON `<localfile>` for `/var/log/zeek-custom/data_exfiltration.log`, with PCRE2 restrictions on `exfil_adaptive_decision` and `exfil_slow_window_decision`.
3. Confirm the file is readable by the agent (`zeek:wazuh`, mode `0640` in the validated VM) and that log collection starts successfully.
4. Check Manager rules `111940–111948` with `wazuh-analysisd -t`; source-specific correlation requires matching `src_ip` and appropriate event order/timeframes.

```bash

# On ZeekVM

sudo /opt/zeek/bin/zeekctl check
sudo /var/ossec/bin/wazuh-logcollector -t
sudo grep -n -C 4 'data_exfiltration.log' /var/ossec/etc/ossec.conf
sudo tail -n 80 /var/ossec/logs/ossec.log

# On Wazuh Manager

sudo /var/ossec/bin/wazuh-analysisd -t
```

For `111945`, two eligible **destination** Adaptive candidates from the same source must occur in the correlation period. For `111946`, the XML counts three same-source Slow destination candidates but does not itself require distinct destinations. `111948` correlates persistent Slow *candidate state*, not necessarily new outbound bytes. Do not use these rules as proof that sensitive data was stolen.

## Active Response does not execute

Check whether the response block is enabled, whether the triggering rule ID is correct, and whether the executable/runtime configuration exists with appropriate permissions. Review:

```bash
sudo tail -n 100 /var/ossec/logs/active-responses.log
sudo grep -iE "active-response|error" /var/ossec/logs/ossec.log | tail -n 100
```

## Publication safety check fails

Search the staged diff for secrets and runtime artifacts before commit. Pay particular attention to webhook URLs with query-string signatures, SSH/private keys, passwords, raw logs, and compiled binaries.
