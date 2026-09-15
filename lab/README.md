# Wazuh-Zeek Security Monitoring Lab

This repository documents a reproducible cybersecurity laboratory that combines Proxmox, Zeek, Wazuh, Auditd, AppArmor, pfSense, and MikroTik RouterOS.

The project focuses on multi-source detection engineering: network behavior observed by Zeek is correlated with endpoint telemetry collected by Wazuh and Auditd, while AppArmor is used to demonstrate application confinement on ServerDB. The current laboratory also includes custom network-scanning detection and correlation of scanning activity that occurs after an earlier reverse-shell detection.

## Objectives

- Detect suspicious downloads and reverse-shell behavior with custom Zeek scripts.
- Correlate Zeek network events with endpoint Auditd connection/process context.
- Detect privileged execution through Auditd keys and custom Wazuh rules.
- Detect anomalous outbound traffic that may indicate data exfiltration.
- Detect ARP, TCP, UDP, address, and ICMP scanning patterns with custom Zeek scripts.
- Correlate post-compromise scanning with earlier reverse-shell detections.
- Collect and classify AppArmor denials from ServerDB through Wazuh.
- Compare AppArmor complain and enforce behavior for an intentionally vulnerable laboratory service.
- Preserve reduced evidence and keep secrets, binaries, raw logs, and runtime credentials out of Git.

## High-level architecture

```text
AttackerVM
    |
    v
pfSense / RouterOS
    |
    +----------------------> ClientVM
    |                           |
    |                           +--> Auditd / Wazuh Agent
    |
    +----------------------> ServerDB
    |                           |
    |                           +--> AppArmor / Audit subsystem / Wazuh Agent
    |
    +--> Proxmox OVS mirror --> ZeekVM --> Wazuh Agent
                                          |
                                          v
                                      Wazuh Manager
                                          |
                                          +--> Decoders and base rules
                                          +--> Cross-source correlation
                                          +--> Active Response / quarantine
```

## Repository structure

| Path | Purpose |
|---|---|
| `docs/` | Architecture, methodology, setup, observability gaps, topology, and troubleshooting |
| `proxmox/` | Bridges, Open vSwitch mirroring, routing, and VM inventory |
| `network/` | VLAN, pfSense, and RouterOS configuration |
| `blue-team/zeek/` | Zeek site policy, custom detections, helper scripts, and sample schemas |
| `blue-team/auditd/` | Endpoint audit rules for process and connection visibility |
| `blue-team/apparmor/` | ServerDB AppArmor profile and confinement notes |
| `blue-team/wazuh/` | Agent configurations, decoders, rules, manager notes, and Active Response |
| `infrastructure/` | Endpoint/server roles and the controlled ServerDB laboratory service |
| `scenarios/` | Defensive validation workflows for reverse shell, privilege escalation, data exfiltration, scanning, and AppArmor |
| `evidence/` | Reduced and sanitized evidence suitable for publication |
| `red-team/` | Sanitized scenario notes only; reusable offensive command lines are intentionally not published |

## Detection flows

### Reverse shell

1. Zeek identifies suspicious connection behavior and lifecycle stages.
2. Auditd records a successful outbound `connect()` from the Linux endpoint.
3. Wazuh correlates network and endpoint evidence using destination, process, filename, and timing fields.
4. Higher-severity correlation rules represent stronger agreement between independent evidence sources.
5. High-confidence rules can feed evidence collection and RouterOS quarantine workflows.

### Network scanning

The custom scanning package writes JSON events to `/var/log/zeek-custom/scanning.log` for:

- ARP host discovery (`host_scan`);
- TCP port scanning (`port_scan`);
- UDP port scanning (`udp_port_scan`);
- same-port scanning across multiple addresses (`address_scan`);
- ICMP host discovery (`icmp_host_scan`).

Wazuh rules `100915-100919` classify the individual events. Rules `120927-120934` correlate scanning with an earlier reverse-shell stage from the same `src_ip`.

### AppArmor on ServerDB

ServerDB runs an intentionally vulnerable inventory service for controlled security validation. AppArmor audit events are collected from `/var/log/audit/audit.log`, decoded by `apparmor_audit`, and classified by rules in the `130900-130983` range. In complain mode policy violations are observable; in enforce mode denied operations are blocked.

### Data exfiltration

A custom Zeek script learns an outbound traffic baseline and emits a behavioral alert when the current volume exceeds the calculated threshold. This is an anomaly signal, not proof of data theft, and must be interpreted with host role, destination, and endpoint evidence.

## Publication safety

This public repository should not contain live credentials, enrollment secrets, private keys, signed webhook URLs, compiled laboratory binaries, raw Auditd archives, rotated Zeek logs, complete packet captures, malicious payloads, or reusable offensive command sequences.

Private laboratory IP addresses may remain when they are intentionally part of the reproducible topology, but all secrets must be replaced with placeholders.

## Start here

1. Read `docs/architecture.md`.
2. Review `docs/network-topology.md`.
3. Follow `docs/setup.md`.
4. Review `blue-team/zeek/site/custom_scripts/scanning/README.md` and `blue-team/apparmor/README.md`.
5. Study the controlled workflows in `scenarios/`.
6. Use `docs/troubleshooting.md` during validation.

## License

See `LICENSE`.
