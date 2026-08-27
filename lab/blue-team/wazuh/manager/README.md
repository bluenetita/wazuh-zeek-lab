# Wazuh Manager Configuration

This directory contains a sanitized copy of the manager configuration:

```text
ossec.conf -> /var/ossec/etc/ossec.conf
```

## Main functions

- receives secure agent traffic on TCP 1514;
- supports agent enrollment on TCP 1515;
- loads default and custom decoders/rules;
- enables inventory, SCA, FIM, rootcheck, and vulnerability detection;
- collects manager-local logs;
- defines standard and custom Active Response commands;
- optionally forwards alerts to a custom Teams/Power Automate integration.

## Custom components

The configuration references:

- `collect_reverse_shell_evidence.sh`;
- `routeros_quarantine.py`;
- custom decoder directory `etc/decoders`;
- custom rule directory `etc/rules`;
- `/var/ossec/logs/active-responses.log`.

The Power Automate URL is intentionally replaced with `POWER_AUTOMATE_WEBHOOK_URL_REDACTED`.

## Important review point

The current evidence-collection Active Response is configured as a timed response sent to `all` agents, while the script is a one-shot collector and does not implement a delete/rollback action. Review this block before reuse and target the intended ClientVM explicitly.

## Validation

```bash
sudo /var/ossec/bin/wazuh-analysisd -t
sudo /var/ossec/bin/wazuh-logcollector -t
sudo systemctl restart wazuh-manager
sudo systemctl status wazuh-manager --no-pager
```

Do not commit certificates, private keys, `client.keys`, `authd.pass`, RouterOS runtime configuration, or real webhooks.
