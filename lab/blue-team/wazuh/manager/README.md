# Wazuh Manager Configuration

The manager loads the custom decoder and rule directories already present in the project. The scanning/AppArmor update therefore does not require an additional `<decoder_dir>` or `<rule_dir>` entry when the existing manager configuration is retained.

## New files loaded by the existing ruleset directories

```text
etc/decoders/001_apparmor_decoder.xml
etc/rules/002_zeek_rules_custom.xml
etc/rules/005_zeek_scanning_correlation.xml
etc/rules/006_app_armor.xml
```

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
