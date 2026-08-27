# Troubleshooting

## Zeek receives no traffic

```bash
ip -br link
sudo tcpdump -ni <MIRROR_INTERFACE>
sudo /opt/zeek/bin/zeekctl diag
```

Check VLAN 999, OVS mirror configuration, interface state, and Zeek `node.cfg`.

## Custom Zeek log is missing

```bash
sudo /opt/zeek/bin/zeekctl check
sudo grep -R "@load" /opt/zeek/share/zeek/site
sudo journalctl -u zeek -n 100 --no-pager
```

Verify script load paths and output-directory permissions.

## Wazuh does not ingest a log

Check the agent `<localfile>` path, log format, file permissions, and agent log:

```bash
sudo tail -n 100 /var/ossec/logs/ossec.log
```

Restart the agent after adding a new monitored file.

## Decoder or rule does not match

```bash
sudo /var/ossec/bin/wazuh-logtest
sudo /var/ossec/bin/wazuh-analysisd -t
```

Verify parent rule, decoder name, extracted fields, location, Auditd key, and JSON schema.

## Correlation stops early

Confirm that intermediate rule IDs triggered, fields have identical representations, events arrived within the timeframe, and `global_frequency` is used when events come from different agents.

## Active Response does not execute

Check whether the block is commented, whether the rule ID is correct, and whether the executable exists with appropriate permissions.

```bash
sudo tail -n 100 /var/ossec/logs/active-responses.log
sudo grep -iE "active-response|error" /var/ossec/logs/ossec.log | tail -n 100
```

## RouterOS SSH failure

Test with the same identity and account used by Wazuh:

```bash
sudo -u wazuh ssh -i /var/ossec/.ssh/routeros_quarantine \
  -o BatchMode=yes -o StrictHostKeyChecking=yes \
  wazuh-quarantine@10.3.0.1 '/ip firewall address-list print'
```

Verify the host key, key permissions, RouterOS user, SSH service, and firewall reachability.

## Quarantine does not interrupt the shell

Check that the address appears in `Quarantine`, firewall rules are ordered before broad accepts/FastTrack, and connection entries were removed.

## Data-exfiltration baseline does not complete

Confirm that the monitored internal host generates payload-bearing outbound TCP traffic in at least five one-minute windows. Internal-to-internal traffic, response-direction traffic, packets without payload, and UDP traffic are not counted by the current script.

```bash
sudo tail -f /var/log/zeek-custom/data_exfiltration.log
sudo /opt/zeek/bin/zeekctl check
```

A Zeek restart or redeploy resets the in-memory baseline.

## Data-exfiltration alert does not trigger

Verify that:

- rule `100913` already confirmed baseline completion;
- `total_orig_bytes` exceeds `dynamic_threshold` within one calculation window;
- the source is in an internal subnet and the destination is outside the configured internal subnets;
- the traffic crosses the OVS mirror observed by ZeekVM;
- the Wazuh agent monitors `/var/log/zeek-custom/data_exfiltration.log`;
- Wazuh rule `100914` is loaded.

A transfer spread across multiple windows or a low-and-slow pattern may remain below the per-window threshold.
