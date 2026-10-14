# Zeek Custom Log Integration

Zeek writes custom JSON logs below `/var/log/zeek-custom/`. The Wazuh Agent on ZeekVM monitors those files and forwards events to the manager.

## Expected files

```text
possible_malware.log
reverse_shell_live.log
reverse_shell_movement.log
reverse_shell_final.log
data_exfiltration.log
scanning.log
ssh_bruteforce.log
mitm_arp.log
mitm_dhcp.log
mitm_dns.log
icmp_flood.log
```

## Processing flow

```text
Zeek script -> JSON log -> Wazuh Agent -> JSON decoder -> custom rule -> correlation
```

Field names in Zeek scripts, Wazuh rules, and evidence examples must remain consistent. After a configuration change, validate it and then restart the appropriate Wazuh Agent in a controlled maintenance window.

## ICMP Echo Flood path

Zeek writes JSON records to `/var/log/zeek-custom/icmp_flood.log` when the destination-specific sliding window crosses its experimental threshold. The ZeekVM agent explicitly collects that file, and Wazuh Manager rule `100940` uses both the event's `event_type` and the log **location**. To validate a sample manually:

```bash
sudo /var/ossec/bin/wazuh-logtest -l /var/log/zeek-custom/icmp_flood.log
```

Do not replace the dedicated inputs with a broad overlapping `*.log` collection. Do not forward the optional `icmp_flood_metrics.log` diagnostic stream as an alert feed by default. See the [scenario](../../../scenarios/icmp-flood/README.md) and [agent reference](../agent-configs/README.md).

The detector reports sensor observations, not unique ICMP requests. OVS mirroring may duplicate a routed packet, and a source address in an ICMP header can be spoofed; attribution stays unverified.

The Microsoft Teams/Power Automate notification integration is separate from this log-ingestion path. Real webhook URLs must never be committed.
