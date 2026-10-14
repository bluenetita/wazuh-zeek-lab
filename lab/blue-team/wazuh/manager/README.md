# Wazuh Manager Configuration

The manager loads the custom decoder and rule directories already present in the project. The ICMP Flood addition does not require an extra `<decoder_dir>` or `<rule_dir>` entry when those existing custom ruleset paths are retained. Copying documentation into a Git checkout does **not** deploy any rule to the live Wazuh Manager.

## New files loaded by the existing ruleset directories

```text
etc/decoders/001_apparmor_decoder.xml
etc/rules/002_zeek_rules_custom.xml
etc/rules/005_zeek_scanning_correlation.xml
etc/rules/006_app_armor.xml
etc/rules/007_mitm_rules.xml
etc/rules/008_zeek_icmp_flood_rules.xml
etc/rules/9999_ssh_bruteforce_correlation.xml
```

## ICMP Echo Flood

Manager rule `100940` (level 8; ATT&CK `T1498.001`) uses existing JSON parent `100900`. Its event_location constraint requires `icmp_flood.log`. Use an event excerpt from [`../../../evidence/icmp-flood/`](../../../evidence/icmp-flood/README.md) and:

```bash
sudo /var/ossec/bin/wazuh-logtest -l /var/log/zeek-custom/icmp_flood.log
```

Automatic RouterOS quarantine is **not** enabled for this alert. The detector does not verify the packet source. Before deploying, compare the checked-in XML with the actual Manager configuration, back up affected runtime files, and verify rule-ID uniqueness.

## Validation

```bash
sudo /var/ossec/bin/wazuh-analysisd -t
sudo /var/ossec/bin/wazuh-logcollector -t
sudo systemctl restart wazuh-manager
sudo systemctl status wazuh-manager --no-pager
```

## Secret handling

The public repository must contain only a placeholder for any Teams/Power Automate webhook. A signed workflow URL is a credential-like secret and should be stored outside Git. Do not commit certificates, private keys, `client.keys`, `authd.pass`, RouterOS runtime credentials, or real webhooks.

## Response note

Scanning and AppArmor detections are added as detection/correlation coverage in this update. Do not automatically attach containment actions to every medium-confidence scan or AppArmor denial without a separate response design and validation step.
