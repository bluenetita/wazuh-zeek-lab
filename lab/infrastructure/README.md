# Infrastructure

This directory documents the internal cyber-range VMs and their role in the scenarios.

## Main systems

| Directory / Host | VLAN | Role |
|---|---:|---|
| `client-linux/` / Client-Linux | 20 | primary Linux endpoint; reverse shell, Auditd, A1 source in SSH tests |
| Client-Linux2 | 20 | SSH validation clone, A2 source (`10.3.20.4`) |
| `client-windows/` | 20 | internal Windows endpoint |
| `server-db/` / ServerDB | 30 | internal server, inventory service, AppArmor, SSH victim V1 |
| ServerDB2 | 30 | SSH validation clone, V2 victim (`10.3.30.4`) |
| `victim-server/` | 30 | historical/legacy documentation for an earlier target |

The A2/V2 clones are documented in the validation topology and do not require a complete duplicate of the same configurations in the repository.

## Observability

Linux endpoints and ServerDB send events to the Wazuh Manager through agents. Network traffic crossing the mirror point is observed by Zeek. This combination makes cross-source correlation testable.

## ServerDB

ServerDB hosts the inventory service used in the vulnerable-service/AppArmor scenario and provides the `sshd` logs required to normalize the destination endpoint in the SSH scenario.

## Client-Linux

Client-Linux is the primary endpoint for reverse-shell tests and Auditd telemetry and is also A1 in the multi-host SSH tests. RouterOS quarantine was validated against its IP during the Active Response campaign.
