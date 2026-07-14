# Setup Guide

## Recommended order

1. Deploy the Proxmox bridges and VLANs.
2. Configure pfSense and RouterOS routing/firewall policy.
3. Configure the OVS mirror and VLAN 999 capture path.
4. Install and configure ZeekVM.
5. Install Wazuh agents on ZeekVM and ClientVM.
6. Install Auditd rules on ClientVM.
7. Install custom Wazuh decoders and rules on the manager.
8. Validate individual events with `wazuh-logtest`.
9. Install Active Response scripts and runtime configuration.
10. Run controlled scenario tests and collect sanitized evidence.

## Zeek

Deploy files from [`blue-team/zeek/`](../blue-team/zeek/) to the appropriate Zeek paths. Validate configuration before restart:

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl deploy
```

## Auditd

Copy rules from [`blue-team/auditd/rules.d/`](../blue-team/auditd/rules.d/) to `/etc/audit/rules.d/`, then load and verify them:

```bash
sudo augenrules --load
sudo auditctl -l
```

## Wazuh Manager

Copy custom decoders and rules to:

```text
/var/ossec/etc/decoders/
/var/ossec/etc/rules/
```

Validate and restart:

```bash
sudo /var/ossec/bin/wazuh-analysisd -t
sudo systemctl restart wazuh-manager
```

## Active Response

Deploy:

```text
collect_reverse_shell_evidence.sh -> ClientVM /var/ossec/active-response/bin/
routeros_quarantine.py           -> Manager  /var/ossec/active-response/bin/
routeros.conf                     -> Manager  /etc/wazuh-routeros/
```

Keep the SSH private key and real runtime configuration outside Git.

## Data-exfiltration validation

The custom Zeek detector requires a learning phase before it can generate anomaly alerts.

1. Confirm that `data_exfiltration.zeek` is loaded.
2. Generate representative authorized outbound TCP traffic for at least five one-minute windows.
3. Confirm `baseline_completed` and Wazuh rule `100913`.
4. Generate a benign authorized transfer that exceeds the learned threshold.
5. Confirm `possible_data_exfiltration` and Wazuh rule `100914`.

Monitor:

```bash
sudo tail -f /var/log/zeek-custom/data_exfiltration.log
```

See [`scenarios/data-exfiltration/`](../scenarios/data-exfiltration/) for the complete controlled procedure and limitations.

## Final validation

Confirm:

- Zeek receives mirrored packets;
- custom logs are created;
- Wazuh receives both agents;
- Auditd keys appear in events;
- decoder fields are populated;
- correlation rules trigger in the expected order;
- evidence archives are created;
- RouterOS receives the victim address and terminates active connections.
