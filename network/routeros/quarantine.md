# RouterOS Automated Quarantine

RouterOS provides the network-containment layer used by the Wazuh Active Response workflow.

When Wazuh detects a high-confidence reverse-shell event, the Wazuh Manager connects to RouterOS through SSH and places the affected endpoint in the `Quarantine` firewall address list.

The Active Response also removes existing connection-tracking entries involving the affected endpoint, interrupting active sessions such as a reverse shell.

## Architecture

The quarantine workflow involves the following components:

* Wazuh Manager;
* Wazuh Active Response;
* `routeros_quarantine.py`;
* SSH public-key authentication;
* the dedicated RouterOS user `wazuh-quarantine`;
* the RouterOS `Quarantine` address list;
* RouterOS firewall filter rules;
* RouterOS connection tracking.

## Workflow

```text
Zeek network event
        +
Auditd endpoint event
        |
        v
Wazuh correlation rule
        |
        v
High-confidence reverse-shell alert
        |
        v
Wazuh Active Response
        |
        v
routeros_quarantine.py
        |
        v
SSH connection to RouterOS
        |
        +--> Victim IP added to Quarantine
        |
        +--> Source connections removed
        |
        +--> Destination connections removed
        |
        v
Firewall restrictions applied
        |
        v
Active reverse-shell session interrupted
```

## Wazuh-side implementation

The Active Response script is stored in:

```text
blue-team/wazuh/active-response/manager/routeros_quarantine.py
```

On the Wazuh Manager, it is deployed at:

```text
/var/ossec/active-response/bin/routeros_quarantine.py
```

The runtime configuration is stored at:

```text
/etc/wazuh-routeros/routeros.conf
```

A repository-safe example is available at:

```text
blue-team/wazuh/active-response/manager/routeros.conf.example
```

The current configuration uses:

```ini
ROUTEROS_USER="wazuh-quarantine"
ROUTEROS_HOST="10.3.0.1"
ROUTEROS_SSH_KEY="/var/ossec/.ssh/routeros_quarantine"
QUARANTINE_LIST="Quarantine"
```

The real SSH private key is stored only on the Wazuh Manager and is not included in the repository.

## Wazuh Active Response configuration

The Wazuh Manager defines the RouterOS quarantine command as follows:

```xml
<command>
  <name>quarantine-routeros</name>
  <executable>routeros_quarantine.py</executable>
  <timeout_allowed>no</timeout_allowed>
</command>
```

The command is executed directly on the Wazuh Manager:

```xml
<active-response>
  <command>quarantine-routeros</command>
  <location>server</location>
  <rules_id>120902,120905,120908,120911,120915,120918,120922,120925</rules_id>
</active-response>
```

The configured rule IDs correspond to the reverse-shell movement stage of the Wazuh correlation chains.

At this stage, Wazuh has correlated endpoint and network evidence and has observed traffic associated with the suspicious connection.

The response does not implement an automatic rollback:

```xml
<timeout_allowed>no</timeout_allowed>
```

An endpoint therefore remains in quarantine until an administrator explicitly removes it.

## Victim IP extraction

The Python script extracts the endpoint address from:

```text
parameters.alert.data.src_ip
```

The field must contain the IP address of the affected endpoint.

The script validates the value with Python's `ipaddress` module before using it in a RouterOS command.

If no valid address is available, the script stops and records an error instead of applying quarantine.

## Dedicated RouterOS user

The Wazuh Manager connects to RouterOS using:

```text
wazuh-quarantine
```

The current RouterOS configuration is:

```routeros
/user
add comment="Wazuh quarantine automation" group=write name=wazuh-quarantine
```

The account uses the built-in RouterOS `write` group.

The account configuration is stored in:

```text
network/routeros/config/wazuh-quarantine-user.rsc
```

Authentication is performed through an SSH public key imported into RouterOS.

The private key remains on the Wazuh Manager at:

```text
/var/ossec/.ssh/routeros_quarantine
```

Neither the private key nor the imported public-key material is stored in the repository.

### Current access restriction

The current RouterOS user configuration contains:

```text
address=""
```

This means that the account is not currently restricted to a specific source address.

For a hardened deployment, the account should be restricted to the address used by the Wazuh Manager to reach RouterOS.

The repository documents the current laboratory configuration and does not add an address restriction that is not present on the router.

## SSH configuration

The Python script invokes SSH using:

```text
BatchMode=yes
StrictHostKeyChecking=yes
```

`BatchMode=yes` prevents interactive password prompts.

`StrictHostKeyChecking=yes` requires the RouterOS host key to be known and trusted before the Active Response executes.

The Wazuh Manager must therefore contain a valid host-key entry for RouterOS.

The script uses the identity file configured through:

```ini
ROUTEROS_SSH_KEY="/var/ossec/.ssh/routeros_quarantine"
```

## Quarantine address list

The affected endpoint is added dynamically to the RouterOS firewall address list:

```text
Quarantine
```

The Python script first verifies whether the address is already present.

Conceptually, it performs:

```routeros
:if ([:len [/ip firewall address-list find list=Quarantine address=VICTIM_IP]] = 0) do={
    /ip firewall address-list add \
        list=Quarantine \
        address=VICTIM_IP \
        comment="Wazuh alert information"
}
```

This makes the operation idempotent: repeated alerts do not create duplicate entries for the same address.

The address-list comment includes sanitized information such as:

* Wazuh rule ID;
* rule description;
* Wazuh agent name.

Current address-list entries are runtime state and are not included in the repository.

## Firewall enforcement

RouterOS firewall rules reference the `Quarantine` address list and restrict traffic involving quarantined endpoints.

The relevant sanitized rules are stored in:

```text
network/routeros/config/quarantine-firewall.rsc
```

The exact effect depends on the firewall policy configured on RouterOS.

The quarantine rules must be evaluated before generic forwarding or FastTrack rules that could otherwise allow the traffic.

Adding an address to the list controls new packets, but an already established connection can remain present in the RouterOS connection-tracking table.

For this reason, the workflow also removes existing connections.

## Connection termination

The Python script removes RouterOS connection-tracking entries where the affected endpoint appears as either the source or destination.

Conceptually, the following operations are executed:

```routeros
/ip firewall connection remove \
    [find where src-address~"^VICTIM_IP"]

/ip firewall connection remove \
    [find where dst-address~"^VICTIM_IP"]
```

This action is important because adding an endpoint to a firewall address list alone may not immediately terminate an already established TCP session.

Removing the connection-tracking entries causes the active reverse-shell connection to be interrupted.

## Active Response logging

The Python script writes its results to:

```text
/var/ossec/logs/active-responses.log
```

A successful operation produces a message similar to:

```text
routeros_quarantine: Quarantined ip=VICTIM_IP rule_id=RULE_ID agent=AGENT_NAME and removed active connections
```

Errors are recorded using:

```text
routeros_quarantine: ERROR: ...
```

Possible failure conditions include:

* no Wazuh message received;
* malformed JSON;
* unsupported Active Response command;
* missing victim IP;
* invalid IP address;
* missing configuration value;
* missing SSH key;
* unknown RouterOS host key;
* SSH authentication failure;
* RouterOS command failure;
* SSH timeout.

The logs must not contain passwords, private-key contents or other authentication secrets.

## Manual validation

### Verify the RouterOS account

On RouterOS:

```routeros
/user print detail where name="wazuh-quarantine"
```

### Verify the imported SSH key

```routeros
/user ssh-keys print detail where user="wazuh-quarantine"
```

### Test the SSH connection

From the Wazuh Manager:

```bash
sudo -u wazuh ssh \
  -i /var/ossec/.ssh/routeros_quarantine \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=yes \
  wazuh-quarantine@10.3.0.1 \
  '/ip firewall address-list print where list="Quarantine"'
```

### Verify quarantined addresses

On RouterOS:

```routeros
/ip firewall address-list print detail where list="Quarantine"
```

### Verify active connections

Replace `VICTIM_IP` with the affected endpoint address:

```routeros
/ip firewall connection print detail where src-address~"^VICTIM_IP"
```

```routeros
/ip firewall connection print detail where dst-address~"^VICTIM_IP"
```

### Verify Wazuh execution

On the Wazuh Manager:

```bash
sudo tail -n 100 /var/ossec/logs/active-responses.log
```

A complete test should verify that:

1. a configured Wazuh correlation rule triggers;
2. `routeros_quarantine.py` is executed on the manager;
3. the correct victim address is extracted;
4. the address is added to `Quarantine`;
5. the firewall restrictions take effect;
6. existing connections are removed;
7. the reverse-shell session is interrupted;
8. the management connection to the endpoint behaves as expected.

## Manual recovery

Removing a system from quarantine is a manual administrative action.

On RouterOS:

```routeros
/ip firewall address-list remove \
  [find where list="Quarantine" address="VICTIM_IP"]
```

After removing the address, verify:

```routeros
/ip firewall address-list print detail where list="Quarantine"
```

Normal connectivity should be restored only after confirming that:

* the reverse-shell process has been terminated;
* the malicious payload has been removed;
* persistence mechanisms have been investigated;
* credentials have been reviewed;
* the endpoint has been remediated;
* relevant evidence has been collected;
* the incident has been documented.

## Security considerations

The RouterOS quarantine workflow performs an automatic network-containment action and must only be associated with high-confidence Wazuh rules.

A false positive could isolate a legitimate endpoint and terminate its active connections.

The implementation should therefore enforce the following controls:

* use a dedicated RouterOS account;
* use SSH public-key authentication;
* validate the victim IP;
* restrict the allowed victim network where possible;
* protect the SSH private key;
* protect the runtime configuration;
* use strict SSH host-key verification;
* log every containment action;
* trigger quarantine only from high-confidence correlation rules;
* keep recovery as a separate administrative action.

The built-in `write` group is broader than a purpose-built least-privilege group.

A future hardening improvement is to create a dedicated RouterOS group containing only the permissions required to:

* use SSH;
* read the relevant firewall state;
* add entries to the quarantine address list;
* remove connection-tracking entries.

## Repository exclusions

The following data must not be committed:

```text
/etc/wazuh-routeros/routeros.conf
/var/ossec/.ssh/routeros_quarantine
/var/ossec/.ssh/known_hosts
```

The repository must also exclude:

* RouterOS passwords;
* SSH private keys;
* SSH public-key files;
* full RouterOS exports;
* RouterOS binary backups;
* active quarantine entries;
* live connection-tracking data;
* unredacted Active Response logs;
* Power Automate webhook URLs;
* API tokens and other credentials.

## Related files

```text
blue-team/wazuh/active-response/manager/routeros_quarantine.py
blue-team/wazuh/active-response/manager/routeros.conf.example
blue-team/wazuh/manager/ossec.conf
blue-team/wazuh/rules/004_zeek_auditd_correlation.xml
network/routeros/config/wazuh-quarantine-user.rsc
network/routeros/config/quarantine-firewall.rsc
network/routeros/firewall-rules.md
```

## Limitations

The quarantine workflow depends on:

* availability of the Wazuh Manager;
* network connectivity between Wazuh and RouterOS;
* successful SSH authentication;
* a trusted RouterOS host key;
* correct extraction of `data.src_ip`;
* correct firewall-rule ordering;
* correct use of the `Quarantine` address list;
* permission to modify address lists and connection tracking.

The implementation does not currently provide:

* automatic removal from quarantine;
* an approval workflow;
* automatic expiry of quarantine entries;
* centralized evidence transfer;
* automatic endpoint remediation;
* dedicated least-privilege RouterOS policies;
* protection against quarantining an authorized management system beyond IP validation.

These operations must be handled through separate procedures or future improvements.
