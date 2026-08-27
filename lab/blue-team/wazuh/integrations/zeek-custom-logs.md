# Zeek Custom Log Integration

Zeek writes custom JSON logs below `/var/log/zeek-custom/`. The Wazuh Agent on ZeekVM monitors those files and forwards events to the manager.

## Expected files

```text
possible_malware.log
reverse_shell_live.log
reverse_shell_movement.log
reverse_shell_final.log
data_exfiltration.log
```

## Processing flow

```text
Zeek script -> JSON log -> Wazuh Agent -> JSON decoder -> custom rule -> correlation
```

Field names in Zeek scripts, Wazuh rules, and evidence examples must remain consistent. Restart the Wazuh Agent after introducing a newly monitored file.

The Microsoft Teams/Power Automate notification integration is separate from this log-ingestion path. Real webhook URLs must never be committed.
