# Wazuh Log Samples

This directory is reserved for reduced events used with `wazuh-logtest` and documentation.

Samples may cover:

- Zeek custom JSON events;
- enriched Auditd connection events;
- privileged-command Auditd events;
- AppArmor audit messages;
- Active Response log lines.

Each sample should identify the expected decoder and rule ID. Replace sensitive addresses, usernames, paths, hashes, and timestamps when they are not essential.

Do not include complete `alerts.json`, `archives.json`, `ossec.log`, credentials, webhooks, or evidence archives.
