# Wazuh Active Response

This directory contains the custom Wazuh Active Response components used to perform automated incident-response actions in the laboratory.

The current implementation focuses on collecting volatile evidence from `ClientVM` after a high-confidence reverse-shell correlation alert.

## Directory structure

```text
active-response/
├── README.md
└── agent/
    └── collect_reverse_shell_evidence.sh
```

The corresponding Wazuh Manager configuration is stored separately in:

```text
blue-team/wazuh/manager/active-response-reverse-shell.conf
```

## Objectives

The response and containment workflow designed for the reverse-shell scenario includes:

1. automated evidence collection;
2. containment of the suspicious process;
3. blocking of the malicious IP address;
4. isolation of the affected virtual machine.

The component currently documented in this directory implements the first phase: automated evidence collection.

The other containment actions must be documented through their corresponding scripts and configuration files when they are added to the repository.

## Why evidence collection is required

Many indicators associated with a reverse shell are volatile and may disappear shortly after detection.

Examples include:

* the malicious process;
* the process identifier;
* the parent process;
* the active TCP connection;
* open sockets;
* the logged-in user;
* executed commands;
* Auditd records;
* recent system logs;
* the current process tree.

The evidence collector captures the endpoint state as soon as a high-confidence correlation rule triggers.

## Evidence collection script

The script:

```text
agent/collect_reverse_shell_evidence.sh
```

is deployed on `ClientVM` at:

```text
/var/ossec/active-response/bin/collect_reverse_shell_evidence.sh
```

The script is executed by the Wazuh Agent after receiving an Active Response command from the Wazuh Manager.

## Trigger rules

The collector is associated with the final rules of the reverse-shell correlation chains:

```text
120903
120906
120909
120912
120916
120919
120923
120926
```

These rules represent high-confidence detections in which multiple endpoint and network events have been correlated.

They are defined in:

```text
blue-team/wazuh/rules/004_zeek_auditd_correlation.xml
```

The collector is not associated with individual low-confidence events, such as a single outbound connection or a single Zeek heuristic.

This reduces unnecessary evidence collection and limits the amount of sensitive data stored on the endpoint.

## Active Response type

The evidence collector is implemented as a stateless Active Response.

The command is executed once when the associated rule triggers and does not require a rollback operation.

The manager configuration therefore uses:

```xml
<timeout_allowed>no</timeout_allowed>
```

## Execution location

The Active Response uses:

```xml
<location>local</location>
```

This causes the command to run on the Wazuh Agent that generated the triggering endpoint alert.

In the reverse-shell scenario, the target endpoint is:

```text
ClientVM
```

with the Wazuh agent name:

```text
Client-Linux
```

## Evidence directory

The collected evidence is stored locally under:

```text
/var/ossec/active-response/evidence/
```

The directory is created with restricted permissions:

```bash
sudo mkdir -p /var/ossec/active-response/evidence
sudo chown root:wazuh /var/ossec/active-response/evidence
sudo chmod 750 /var/ossec/active-response/evidence
```

This allows privileged collection while limiting access to unauthorized users.

## Evidence collected

The script creates a temporary timestamped directory and collects the following information.

### System information

File:

```text
system_info.txt
```

Contains:

* collection timestamp;
* hostname;
* kernel information;
* user executing the script.

### Network configuration

Files:

```text
ip_addr.txt
ip_route.txt
```

Contain:

* local network interfaces;
* configured IP addresses;
* routing table;
* default gateway;
* additional routes.

### Process information

File:

```text
process_tree.txt
```

Contains the complete process list in tree format.

This can help identify:

* the process associated with the suspicious connection;
* its parent process;
* active shells;
* interpreters;
* post-exploitation commands;
* processes running with elevated privileges.

### Active network connections

Files:

```text
network_connections_ss.txt
network_connections_lsof.txt
```

Contain information about:

* active TCP connections;
* active UDP sockets;
* listening ports;
* local and remote addresses;
* process identifiers;
* executable names.

The script uses both `ss` and `lsof` to collect complementary views of the endpoint network state.

### Logged-in users

Files:

```text
logged_users.txt
recent_logins.txt
```

Contain:

* currently logged-in users;
* recent login sessions;
* source addresses associated with recent sessions, when available.

### Auditd evidence

Files:

```text
audit_tail.log
audit_rs_connect.log
```

The file `audit_tail.log` contains the last 500 records from:

```text
/var/log/audit/audit.log
```

The file `audit_rs_connect.log` contains interpreted Auditd events associated with the key:

```text
rs_connect
```

These events can provide information such as:

* executable path;
* process name;
* PID and PPID;
* Audit user identifier;
* destination address;
* destination port;
* connection result.

### System journal

File:

```text
journal_tail.log
```

Contains the latest systemd journal entries collected with:

```bash
journalctl -n 300
```

These records can provide additional context about:

* service activity;
* process errors;
* authentication events;
* kernel messages;
* agent activity;
* system changes near the detection timestamp.

## Archive format

After collecting the evidence, the script creates a compressed archive using the following naming convention:

```text
reverse_shell_<HOSTNAME>_<YYYYMMDD_HHMMSS>.tar.gz
```

Example:

```text
reverse_shell_clientvm_20260629_153045.tar.gz
```

The archive is stored under:

```text
/var/ossec/active-response/evidence/
```

After compression, the temporary uncompressed directory is deleted.

## Response flow

```text
Network activity
       |
       v
      Zeek
       |
       v
Reverse-shell custom events
       |
       +-----------------------------+
                                     |
Endpoint connect syscall             |
       |                             |
       v                             |
     Auditd                          |
       |                             |
       v                             |
    Wazuh Agent                      |
       |                             |
       +-------------+---------------+
                     |
                     v
               Wazuh Manager
                     |
                     v
        Reverse-shell correlation chain
                     |
                     v
          High-confidence final rule
                     |
                     v
          Wazuh Active Response command
                     |
                     v
           Wazuh Agent on ClientVM
                     |
                     v
 collect_reverse_shell_evidence.sh
                     |
                     v
       Timestamped evidence archive
```

## Script installation

Copy the script to the Wazuh Active Response directory on `ClientVM`:

```bash
sudo cp collect_reverse_shell_evidence.sh \
  /var/ossec/active-response/bin/
```

Set the owner:

```bash
sudo chown root:root \
  /var/ossec/active-response/bin/collect_reverse_shell_evidence.sh
```

Set the required permissions:

```bash
sudo chmod 750 \
  /var/ossec/active-response/bin/collect_reverse_shell_evidence.sh
```

## Manager configuration

The Wazuh Manager must define the custom command:

```xml
<command>
  <name>collect-reverse-shell-evidence</name>
  <executable>collect_reverse_shell_evidence.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>
```

The command is associated with the high-confidence correlation rules:

```xml
<active-response>
  <command>collect-reverse-shell-evidence</command>
  <location>local</location>
  <rules_id>120903,120906,120909,120912,120916,120919,120923,120926</rules_id>
</active-response>
```

The complete sanitized configuration fragment is stored in:

```text
blue-team/wazuh/manager/active-response-reverse-shell.conf
```

The configuration must be added to the Wazuh Manager file:

```text
/var/ossec/etc/ossec.conf
```

## Manual test

Run the collector manually on `ClientVM`:

```bash
sudo /var/ossec/active-response/bin/collect_reverse_shell_evidence.sh
```

Verify that an archive was created:

```bash
sudo ls -lh /var/ossec/active-response/evidence/
```

Inspect the archive content without extracting it:

```bash
sudo tar -tzf \
  /var/ossec/active-response/evidence/reverse_shell_*.tar.gz
```

The archive should contain:

```text
system_info.txt
ip_addr.txt
ip_route.txt
process_tree.txt
network_connections_ss.txt
network_connections_lsof.txt
logged_users.txt
recent_logins.txt
audit_tail.log
audit_rs_connect.log
journal_tail.log
```

Some files may contain command error messages when an optional dependency is unavailable.

## Configuration validation

Validate the Wazuh Manager configuration:

```bash
sudo /var/ossec/bin/wazuh-analysisd -t
```

Restart the Wazuh Manager:

```bash
sudo systemctl restart wazuh-manager
```

Verify its status:

```bash
sudo systemctl status wazuh-manager --no-pager
```

Restart the Wazuh Agent on `ClientVM`:

```bash
sudo systemctl restart wazuh-agent
```

Verify the agent status:

```bash
sudo systemctl status wazuh-agent --no-pager
```

## Active Response validation

A complete validation must verify that:

1. a final reverse-shell correlation rule triggers;
2. the Wazuh Manager invokes the configured command;
3. the command is delivered to `ClientVM`;
4. the script runs successfully;
5. an evidence archive is created;
6. the archive contains the expected files;
7. the Wazuh Agent remains operational.

Check Active Response activity through:

```text
/var/ossec/logs/active-responses.log
```

Check the Wazuh Agent log through:

```text
/var/ossec/logs/ossec.log
```

Useful commands include:

```bash
sudo tail -n 100 /var/ossec/logs/active-responses.log
```

```bash
sudo grep -iE "active-response|collect-reverse-shell|error" \
  /var/ossec/logs/ossec.log | tail -n 100
```

## Dependencies

The script uses the following commands:

```text
date
hostname
uname
ip
ps
ss
lsof
who
last
tail
ausearch
journalctl
tar
```

The following packages or components are particularly relevant:

* `auditd`, for `ausearch`;
* `lsof`, for process-to-socket mapping;
* `iproute2`, for `ip` and `ss`;
* `systemd`, for `journalctl`;
* `tar`, for evidence compression.

The script checks whether `ausearch` is available before using it.

Other commands write their error output into the corresponding evidence file if they are unavailable.

## Security considerations

The generated evidence archives can contain sensitive information, including:

* usernames;
* hostnames;
* private IP addresses;
* routing information;
* active processes;
* command-line arguments;
* active connections;
* login history;
* Auditd events;
* system journal records;
* local file paths.

Access to the evidence directory must therefore remain restricted.

Raw archives must not be committed to the public repository.

Only reduced and sanitized evidence samples may be stored under:

```text
evidence/reverse-shell/
```

Before publishing an evidence sample, remove or replace:

* usernames;
* hostnames;
* public addresses;
* passwords;
* tokens;
* credentials;
* private keys;
* command-line secrets;
* personal information;
* confidential file paths.

## Retention

The current script creates a new archive every time it runs and does not automatically delete old archives.

Without a retention policy, the evidence directory may consume increasing disk space.

A production deployment should define:

* maximum archive age;
* maximum number of archives;
* maximum directory size;
* secure transfer to central storage;
* integrity verification;
* access logging.

No automatic retention mechanism is implemented in the current laboratory version.

## Limitations

The collector captures the endpoint state at the time the script is executed.

Some evidence may already be unavailable when collection begins, particularly when:

* the suspicious process has terminated;
* the connection has already closed;
* the PID has been reused;
* temporary files have been deleted;
* the attacker has cleared logs;
* log rotation has occurred;
* the endpoint is under heavy load.

The script does not currently:

* terminate the suspicious process;
* block the destination IP;
* remove an active connection;
* change the Proxmox VLAN configuration;
* isolate the virtual machine;
* transfer the archive to central evidence storage;
* calculate hashes of the generated archive;
* apply a retention policy.

These operations belong to the subsequent containment phases and should be implemented and documented as separate response components.

## Repository exclusions

The following files must not be committed:

* generated `.tar.gz` evidence archives;
* raw Auditd logs;
* complete system journal exports;
* unredacted process listings;
* unredacted login histories;
* credentials;
* passwords;
* authentication tokens;
* private SSH keys;
* private TLS keys;
* malicious payloads;
* confidential incident data.

This directory contains only reproducible Active Response scripts and their documentation.
