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

## Data-exfiltration baseline does not complete

Confirm that representative payload-bearing outbound TCP traffic is visible for the required learning windows. A Zeek restart/redeploy resets an in-memory baseline.

## Active Response does not execute

Check whether the response block is enabled, whether the triggering rule ID is correct, and whether the executable/runtime configuration exists with appropriate permissions. Review:

```bash
sudo tail -n 100 /var/ossec/logs/active-responses.log
sudo grep -iE "active-response|error" /var/ossec/logs/ossec.log | tail -n 100
```

## Publication safety check fails

Search the staged diff for secrets and runtime artifacts before commit. Pay particular attention to webhook URLs with query-string signatures, SSH/private keys, passwords, raw logs, and compiled binaries.
