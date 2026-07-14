# Wazuh–Zeek Security Monitoring Lab

This repository documents a reproducible cybersecurity laboratory that combines **Zeek**, **Wazuh**, **Auditd**, **AppArmor**, **Proxmox**, **pfSense**, and **MikroTik RouterOS**.

The project focuses on multi-source detection and response. Network telemetry produced by Zeek is correlated with endpoint telemetry collected by Wazuh and Auditd. High-confidence reverse-shell detections can trigger automated evidence collection and RouterOS-based network quarantine.

## Objectives

- Detect suspicious downloads and reverse-shell behavior with custom Zeek scripts.
- Correlate network events with endpoint `connect()` syscalls and process context.
- Detect privileged execution through Auditd keys and custom Wazuh rules.
- Detect anomalous outbound traffic that may indicate data exfiltration.
- Preserve volatile endpoint evidence after high-confidence alerts.
- Quarantine a suspected endpoint through RouterOS and terminate tracked connections.
- Keep the laboratory reproducible through sanitized configuration and evidence.

## High-level architecture

```text
AttackerVM
    |
    v
pfSense / RouterOS
    |
    +----------------------> ClientVM
    |                           |
    |                           +--> Auditd / AppArmor / Wazuh Agent
    |
    +--> Proxmox OVS mirror --> ZeekVM --> Wazuh Agent
                                      \
                                       +--> Wazuh Manager
                                                |
                                                +--> Correlation rules
                                                +--> Evidence collection
                                                +--> RouterOS quarantine
```

## Repository structure

| Path | Purpose |
|---|---|
| [`docs/`](docs/) | Architecture, methodology, setup, limitations, and troubleshooting |
| [`proxmox/`](proxmox/) | Bridges, Open vSwitch mirroring, routing, and VM inventory |
| [`network/`](network/) | VLAN, pfSense, and RouterOS configuration |
| [`blue-team/zeek/`](blue-team/zeek/) | Zeek scripts, services, log rotation, and sample schemas |
| [`blue-team/auditd/`](blue-team/auditd/) | Endpoint audit rules for process and network visibility |
| [`blue-team/wazuh/`](blue-team/wazuh/) | Agent/manager configuration, decoders, rules, and Active Response |
| [`red-team/`](red-team/) | Sanitized attacker-side network and scenario notes |
| [`infrastructure/`](infrastructure/) | Endpoint and server roles and sanitized configuration |
| [`scenarios/`](scenarios/) | Reverse-shell, privilege-escalation, and data-exfiltration validation workflows |
| [`evidence/`](evidence/) | Reduced and sanitized evidence suitable for publication |

## Main detection flows

### Reverse shell

1. Zeek identifies a suspicious long-lived or unknown-service connection.
2. Auditd records a successful outbound `connect()` syscall on the Linux endpoint.
3. Wazuh correlates destination fields, process information, filenames, and Zeek connection UIDs.
4. Higher-severity rules represent connection start, movement, and final lifecycle stages.
5. Active Response can collect volatile evidence and quarantine the endpoint through RouterOS.

### Privilege escalation

Auditd keys identify SUID execution, root-session commands, `sudo`, `su`, and execution from the monitored downloads directory. Wazuh rules classify these events and attach relevant MITRE ATT&CK mappings where appropriate.

### Data exfiltration

A custom Zeek script learns a baseline for monitored internal hosts and generates an alert when outbound traffic exceeds the calculated threshold. This is a behavioral signal and must be interpreted together with destination, host role, file access, and endpoint evidence.

## Safety and scope

This repository is intended for an isolated laboratory and authorized security testing only. It does not contain live credentials, private keys, malicious payloads, complete packet captures, production exports, or unredacted incident archives.

Before reuse, review all IP addresses, interface names, rule IDs, paths, and firewall ordering for the target environment.

## Start here

1. Read [`docs/architecture.md`](docs/architecture.md).
2. Review [`docs/network-topology.md`](docs/network-topology.md).
3. Follow [`docs/setup.md`](docs/setup.md).
4. Study the scenario documentation in [`scenarios/`](scenarios/).
5. Use [`docs/troubleshooting.md`](docs/troubleshooting.md) during validation.

## License

See [`LICENSE`](LICENSE).
