# Wazuh Manager Configuration

This directory contains the sanitized configuration of the Wazuh Manager deployed in the laboratory.

The configuration documents the central components responsible for:

* receiving events from Wazuh agents;
* loading custom decoders and rules;
* analyzing endpoint and network telemetry;
* generating alerts;
* managing agent enrollment;
* monitoring vulnerabilities;
* executing Active Response actions;
* forwarding selected alerts to external integrations.

## Directory structure

```text
manager/
├── README.md
└── ossec.conf
```

The file `ossec.conf` is a sanitized copy of the configuration deployed on the Wazuh Manager.

The original file is stored on the manager at:

```text
/var/ossec/etc/ossec.conf
```

## Role in the laboratory

The Wazuh Manager is the central analysis and correlation component of the laboratory.

It receives telemetry from multiple systems, including:

* `ZeekVM`, which forwards standard and custom Zeek logs;
* `ClientVM`, which forwards Auditd, File Integrity Monitoring and system events;
* other Linux and Windows endpoints enrolled in the laboratory.

The manager applies decoders and rules to the received events and correlates host-based and network-based evidence.

```text
ZeekVM --------------------------+
                                 |
ClientVM ------------------------+
                                 |
Other Wazuh agents --------------+
                                 |
                                 v
                         Wazuh Manager
                                 |
                   +-------------+-------------+
                   |                           |
                   v                           v
            Custom decoders              Custom rules
                   |                           |
                   +-------------+-------------+
                                 |
                                 v
                         Correlated alerts
                                 |
                   +-------------+-------------+
                   |                           |
                   v                           v
             Active Response             Integrations
```

## Agent communication

The manager listens for secure agent connections using:

```text
Protocol: TCP
Port: 1514
```

The relevant configuration is:

```xml
<remote>
  <connection>secure</connection>
  <port>1514</port>
  <protocol>tcp</protocol>
  <queue_size>131072</queue_size>
</remote>
```

The increased queue size supports bursts of events generated during controlled attack simulations.

## Agent enrollment

The Wazuh authentication service is enabled on:

```text
Port: 1515
```

The manager uses its local certificate and private key through the following paths:

```text
etc/sslmanager.cert
etc/sslmanager.key
```

Only the paths are included in the configuration.

The actual certificate private key must not be committed to the repository.

## Alert configuration

The manager records alerts with a minimum level of:

```text
3
```

Email notifications are disabled in the current laboratory configuration.

```xml
<alerts>
  <log_alert_level>3</log_alert_level>
  <email_alert_level>12</email_alert_level>
</alerts>
```

The manager also produces JSON-formatted event archives through:

```xml
<logall_json>yes</logall_json>
```

This setting increases visibility during laboratory analysis but can generate a significant amount of stored data.

## Custom ruleset

The manager loads both the default Wazuh ruleset and the custom laboratory ruleset.

```xml
<ruleset>
  <decoder_dir>ruleset/decoders</decoder_dir>
  <rule_dir>ruleset/rules</rule_dir>

  <decoder_dir>etc/decoders</decoder_dir>
  <rule_dir>etc/rules</rule_dir>
</ruleset>
```

The custom components are documented under:

```text
blue-team/wazuh/decoders/
blue-team/wazuh/rules/
```

### Custom decoders

The custom decoder directory contains components for:

* Auditd reverse-shell connection events;
* AppArmor audit events.

### Custom rules

The custom rules directory contains components for:

* standard Zeek events;
* custom Zeek reverse-shell events;
* data-exfiltration events;
* Auditd outbound connection events;
* Auditd privileged-command events;
* multi-source Zeek and Auditd correlations.

## Audit key list

The manager loads:

```text
etc/lists/audit-keys
```

This list supports the interpretation and classification of Auditd keys used by Wazuh rules.

The endpoint Auditd configuration is documented under:

```text
blue-team/auditd/
```

## Vulnerability detection

The Vulnerability Detection module is enabled:

```xml
<vulnerability-detection>
  <enabled>yes</enabled>
  <index-status>yes</index-status>
  <feed-update-interval>60m</feed-update-interval>
</vulnerability-detection>
```

The module updates its vulnerability feed every hour and indexes the resulting vulnerability information.

## Wazuh Indexer connection

The manager connects to the local Wazuh Indexer through:

```text
https://127.0.0.1:9200
```

TLS files are referenced through:

```text
/etc/filebeat/certs/root-ca.pem
/etc/filebeat/certs/wazuh-server.pem
/etc/filebeat/certs/wazuh-server-key.pem
```

The repository contains only configuration references.

The real certificate private key must not be committed.

## Security monitoring components

The manager configuration enables the following standard Wazuh capabilities.

### Rootcheck

Rootcheck is enabled and periodically checks:

* system files;
* known trojans;
* devices;
* system directories;
* processes;
* network ports;
* network interfaces.

The scan interval is:

```text
43200 seconds
```

which corresponds to twelve hours.

### System inventory

Syscollector is enabled and gathers:

* hardware information;
* operating-system information;
* network configuration;
* installed packages;
* listening ports;
* running processes;
* users and groups;
* services;
* browser extensions.

The inventory interval is:

```text
1 hour
```

### Security Configuration Assessment

Security Configuration Assessment is enabled with:

```text
scan on start: yes
interval: 12 hours
```

### File Integrity Monitoring

The manager monitors important local directories including:

```text
/etc
/usr/bin
/usr/sbin
/bin
/sbin
/boot
```

New-file alerts are enabled.

The configuration also excludes temporary, volatile and filesystem-specific paths to reduce unnecessary events.

## Local log collection

The manager collects several local sources.

### System commands

The following commands are executed every 360 seconds:

```text
df -P
netstat -tulpn
last -n 20
```

They provide information about:

* filesystem usage;
* listening services;
* recent login sessions.

### System logs

The manager collects:

```text
journald
/var/ossec/logs/active-responses.log
/var/log/dpkg.log
```

These sources support:

* system-event analysis;
* Active Response troubleshooting;
* package-installation auditing.

## Active Response

The manager contains the standard Wazuh Active Response commands, including:

* `disable-account`;
* `restart-wazuh`;
* `firewall-drop`;
* `host-deny`;
* `route-null`;
* Windows route and firewall actions.

The configuration also contains custom definitions for:

```text
collect-reverse-shell-evidence
quarantine-routeros
```

In the current configuration, the custom reverse-shell Active Response section is enclosed in an XML comment and is therefore disabled by default.

This is intentional: containment actions are enabled only during controlled laboratory testing.

## Automated evidence collection

The command:

```text
collect-reverse-shell-evidence
```

invokes:

```text
collect_reverse_shell_evidence.sh
```

The script is deployed on `ClientVM` and is documented under:

```text
blue-team/wazuh/active-response/
```

Its purpose is to collect volatile endpoint evidence, including:

* process tree;
* active network connections;
* logged-in users;
* recent login sessions;
* Auditd records;
* system journal entries;
* network interfaces;
* routing information.

The generated archives are stored locally on the endpoint and must not be committed without sanitization.

## RouterOS quarantine

The command:

```text
quarantine-routeros
```

invokes:

```text
routeros_quarantine.py
```

The script is executed on the Wazuh Manager because it requires access to:

* RouterOS;
* the RouterOS SSH key;
* the quarantine configuration;
* the Proxmox or network-isolation workflow.

Its purpose is to perform containment actions such as:

* adding the affected address to a RouterOS quarantine list;
* terminating active RouterOS connections;
* isolating the virtual machine from its original VLAN.

The custom quarantine configuration is disabled by default and is enabled only during controlled tests.

## Response stages

The reverse-shell response workflow is designed around increasing confidence levels.

```text
Initial suspicious activity
          |
          v
Zeek and Auditd correlation
          |
          v
Reverse-shell start correlation
          |
          v
Automatic evidence collection
          |
          v
Reverse-shell traffic detected
          |
          v
RouterOS quarantine
          |
          v
Connection closure and final alert
```

Evidence collection should occur while processes and sockets may still be present.

Network isolation is associated with higher-confidence correlation stages to reduce the risk of quarantining legitimate systems.

## Active Response logs

Active Response execution is recorded in:

```text
/var/ossec/logs/active-responses.log
```

Useful troubleshooting commands include:

```bash
sudo tail -n 100 /var/ossec/logs/active-responses.log
```

```bash
sudo grep -iE "active-response|quarantine|evidence|error" \
  /var/ossec/logs/ossec.log | tail -n 100
```

## External integration

The manager configuration includes a custom integration named:

```text
custom-teams
```

It forwards selected Wazuh alerts in JSON format to a Power Automate workflow used to deliver notifications to Microsoft Teams.

The configured minimum alert level is:

```text
5
```

The real Power Automate webhook URL is a secret and must not be stored in the repository.

The sanitized configuration must use a placeholder such as:

```xml
<integration>
  <name>custom-teams</name>
  <hook_url>POWER_AUTOMATE_WEBHOOK_URL_REDACTED</hook_url>
  <level>5</level>
  <alert_format>json</alert_format>
</integration>
```

The URL must also be excluded from:

* documentation;
* screenshots;
* alert samples;
* commit history;
* shell history;
* issue descriptions.

If a webhook is accidentally published, it must be revoked and regenerated.

## Cluster configuration

The cluster section is present but disabled:

```xml
<disabled>yes</disabled>
```

The laboratory therefore uses a standalone Wazuh Manager rather than a multi-node Wazuh cluster.

The values:

```text
NODE_IP
empty cluster key
```

are placeholders and do not contain operational secrets.

## Deployment

Back up the existing manager configuration before replacing it:

```bash
sudo cp /var/ossec/etc/ossec.conf \
  /var/ossec/etc/ossec.conf.backup
```

Copy the sanitized configuration to the manager:

```bash
sudo cp ossec.conf /var/ossec/etc/ossec.conf
```

Set the expected ownership and permissions:

```bash
sudo chown root:wazuh /var/ossec/etc/ossec.conf
sudo chmod 640 /var/ossec/etc/ossec.conf
```

Do not overwrite a working manager configuration without first comparing the files.

## Configuration validation

Validate the analysis configuration:

```bash
sudo /var/ossec/bin/wazuh-analysisd -t
```

Test the log collector configuration:

```bash
sudo /var/ossec/bin/wazuh-logcollector -t
```

Test the authentication service configuration:

```bash
sudo /var/ossec/bin/wazuh-authd -t
```

Restart the manager after successful validation:

```bash
sudo systemctl restart wazuh-manager
```

Verify the service:

```bash
sudo systemctl status wazuh-manager --no-pager
```

Check recent errors:

```bash
sudo grep -iE "error|critical|invalid|decoder|rule|active-response" \
  /var/ossec/logs/ossec.log | tail -n 100
```

## Rules and decoder testing

Use the Wazuh log-testing utility to validate decoders and rules:

```bash
sudo /var/ossec/bin/wazuh-logtest
```

Verify the following phases:

```text
Phase 1: Completed pre-decoding
Phase 2: Completed decoding
Phase 3: Completed filtering (rules)
```

Correlation chains must be tested with a complete sequence of events rather than with a single isolated log.

## Sanitization

The repository version of `ossec.conf` must not contain:

* Power Automate webhook URLs;
* webhook signatures;
* passwords;
* API tokens;
* enrollment secrets;
* cluster keys;
* private certificates;
* private TLS keys;
* SSH private keys;
* RouterOS credentials;
* contents of `authd.pass`;
* contents of `client.keys`.

References to local secret files can remain, for example:

```text
etc/sslmanager.key
/etc/filebeat/certs/wazuh-server-key.pem
```

The referenced files themselves must not be committed.

## Files that must not be committed

```text
/var/ossec/etc/client.keys
/var/ossec/etc/authd.pass
/var/ossec/etc/sslmanager.key
/etc/filebeat/certs/wazuh-server-key.pem
/var/ossec/.ssh/*
/etc/wazuh-routeros/routeros.conf
```

Additional exclusions include:

* `.bak` configuration files;
* raw alert archives;
* unredacted logs;
* generated evidence archives;
* production credentials;
* private incident data.

## Repository consistency

When `ossec.conf` changes, verify whether related updates are required in:

```text
blue-team/wazuh/agent-configs/
blue-team/wazuh/active-response/
blue-team/wazuh/decoders/
blue-team/wazuh/rules/
blue-team/wazuh/integrations/
```

Changes to command names, rule IDs, decoder paths or integration names must be reflected consistently across the repository.
