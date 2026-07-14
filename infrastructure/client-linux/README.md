# ClientVM — Linux Endpoint

ClientVM is the primary endpoint used for reverse-shell, privilege-escalation, data-exfiltration, file-monitoring, and quarantine tests.

## Monitoring

- Wazuh Agent;
- Auditd rules from `blue-team/auditd/`;
- FIM for `/home/client/Downloads`;
- AppArmor laboratory profiles where applicable;
- endpoint evidence collection script;
- controlled outbound-transfer generation for data-exfiltration validation.

## Network

The documented laboratory address is `10.3.20.2/24` with the client VLAN gateway at `10.3.20.1`.

## Response

Wazuh can collect volatile evidence from this host. RouterOS can isolate its IP and remove tracked connections. No process-kill response is currently versioned.

Do not publish local credentials, agent keys, personal files, or raw evidence archives.
