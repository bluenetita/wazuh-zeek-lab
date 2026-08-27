# Architecture

## Overview

The laboratory separates network observation, endpoint observation, event correlation, and containment into distinct components.

| Component | Role |
|---|---|
| Proxmox | Hosts the virtual machines and mirrors monitored VLAN traffic |
| pfSense | Controls traffic between the simulated external and internal networks |
| RouterOS | Routes internal networks and enforces automated quarantine |
| ZeekVM | Analyzes mirrored traffic and writes standard and custom logs |
| ClientVM | Linux target monitored by Auditd, AppArmor, FIM, and the Wazuh Agent |
| Wazuh Manager | Decodes, correlates, alerts, and launches Active Response |
| AttackerVM | Generates controlled traffic in authorized scenarios |

## Telemetry flow

```text
Network packets
    |
    v
Proxmox Open vSwitch mirror
    |
    v
ZeekVM
    |
    +--> Standard Zeek JSON logs
    +--> Custom reverse-shell logs
    +--> Custom data-exfiltration log
    |
    v
Wazuh Agent on ZeekVM
    |
    v
Wazuh Manager

ClientVM
    |
    +--> Auditd events
    +--> AppArmor audit events
    +--> File Integrity Monitoring
    +--> System logs
    |
    v
Wazuh Agent on ClientVM
    |
    v
Wazuh Manager
```

## Correlation model

Network-only signals are useful but do not identify the responsible process. Endpoint-only connection events provide process context but do not describe the complete network session. The Wazuh rules therefore correlate:

- source and destination addresses;
- destination ports;
- downloaded and executed filenames;
- executable paths;
- Auditd process and user fields;
- Zeek connection UIDs;
- connection duration, bytes, and packets.

The severity increases as independent evidence sources agree.

## Response architecture

```text
High-confidence Wazuh alert
       |
       +--> Evidence collector on the endpoint
       |
       +--> RouterOS quarantine script on the manager
                         |
                         +--> Add victim IP to `Quarantine`
                         +--> Remove active connection entries
```

The repository currently implements volatile evidence collection and network quarantine. It does **not** include an endpoint process-kill script; process termination must not be claimed as implemented unless a dedicated response component is added and tested.

## Trust boundaries

- The Zeek sensor receives mirrored traffic and does not sit inline.
- The Wazuh Manager is trusted to initiate response actions.
- RouterOS accepts SSH commands only through a dedicated account and key.
- Runtime secrets remain outside the repository.
- Published evidence is reduced and sanitized.
