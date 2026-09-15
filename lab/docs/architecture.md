# Architecture

## Overview

The laboratory separates traffic observation, endpoint observation, correlation, application confinement, and containment into distinct components.

| Component | Role |
|---|---|
| Proxmox | Hosts the virtual machines and mirrors monitored VLAN traffic |
| pfSense | Controls the simulated external/internal boundary used by the lab |
| RouterOS | Routes internal networks and enforces automated quarantine |
| ZeekVM | Analyzes mirrored traffic and writes standard/custom JSON logs |
| ClientVM | Main Linux endpoint monitored by Auditd, FIM, and the Wazuh Agent |
| ServerDB | Controlled server target with AppArmor, Linux Audit telemetry, and a Wazuh Agent |
| Wazuh Manager | Decodes, classifies, correlates, alerts, and launches response actions |
| AttackerVM | Generates authorized laboratory traffic and controlled test activity |

## Network telemetry flow

```text
Monitored VLAN traffic
        |
        v
Proxmox Open vSwitch mirror
        |
        v
ZeekVM
        |
        +--> Standard Zeek JSON logs
        +--> Reverse-shell custom logs
        +--> Data-exfiltration custom log
        +--> scanning.log
        |
        v
Wazuh Agent on ZeekVM
        |
        v
Wazuh Manager
```

## Endpoint telemetry flow

```text
ClientVM
   |
   +--> Auditd connection/process events
   +--> FIM and system logs
   |
   v
Wazuh Agent
   |
   v
Wazuh Manager

ServerDB
   |
   +--> AppArmor decisions through Linux Audit
   +--> /var/log/audit/audit.log
   +--> system/journal logs
   |
   v
Wazuh Agent
   |
   v
Wazuh Manager
```

## Correlation model

Network-only signals describe traffic patterns but usually cannot identify the responsible local process. Endpoint-only events provide process context but do not describe the full network session. The laboratory therefore uses layered rules:

1. low-level observation rules;
2. source-specific detections;
3. cross-source or temporal correlation;
4. response actions only after stronger evidence is available.

The reverse-shell correlation chain uses fields such as source/destination addresses, destination port, process path, filename, Auditd user/process metadata, Zeek connection UID, duration, bytes, packets, and event timing.

The post-compromise scanning chain is simpler: a previously matched reverse-shell correlation is followed by a Zeek scanning event with the same `src_ip` within the configured timeframe.

## AppArmor model

AppArmor is applied to the ServerDB inventory service as an application-confinement control. The repository profile starts in complain mode to support observation and tuning. When switched to enforce mode, operations that are not granted by policy are denied. Wazuh receives the resulting Audit/AppArmor events and classifies file, execution, capability, network, ptrace, mount, signal, D-Bus, and repeated-denial activity.

The commented `deny` examples inside the profile are documentation only. The effective enforce-mode behavior depends on the permissions actually granted by the loaded profile.

## Response architecture

```text
High-confidence Wazuh alert
        |
        +--> Evidence collector on the endpoint
        |
        +--> RouterOS quarantine on the manager
                  |
                  +--> Add victim IP to quarantine list
                  +--> Remove tracked active connections
```

The repository does not claim automatic process termination unless a dedicated, tested endpoint response component is present.

## Trust and publication boundaries

- Zeek is passive and receives mirrored traffic; it is not inline.
- The Wazuh Manager is trusted to initiate configured response actions.
- RouterOS runtime credentials and SSH private keys stay outside Git.
- Signed webhook URLs are treated as secrets.
- Raw Auditd archives, rotated Zeek logs, packet captures, and compiled lab binaries are excluded.
- Published evidence is reduced and sanitized.
