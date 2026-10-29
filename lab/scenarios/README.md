# Scenarios

This directory contains the scenarios that are actually documented in the cyber range. Each scenario links its objective, involved systems, detection logic, and observed results. Reusable offensive payloads, exploits, and similar material are not published.

## Scenarios

| Scenario | Directory | Status | Main components |
|---|---|---|---|
| Reverse Shell | `reverse-shell/` | Validated | Zeek, Auditd, Wazuh |
| Privilege Escalation | `privilege-escalation/` | Validated | Auditd/Wazuh |
| Network Scanning | `network-scanning/` | Validated | Zeek + Wazuh |
| AppArmor Mitigation | `apparmor-mitigation/` | Validated | ServerDB + AppArmor + Wazuh |
| Active Response | `active-response/` | Validated | Wazuh + RouterOS |
| SSH Brute Force | `ssh-bruteforce/` | Validated | Zeek + sshd + Wazuh |
| MITM / Adversary-in-the-Middle | `mitm/` | Validated (positive Zeek path) | Zeek + Wazuh |
| ICMP Echo Flood | `icmp-flood/` | Functionally validated v1.7-rc2 (lab route) | Zeek protected-subnet detector, TTL mirror dedup, Wazuh `100940` |

## Data Exfiltration

The [`data-exfiltration/`](data-exfiltration/README.md) scenario was revalidated as a detection-only completed-TCP-flow implementation on 28 October 2026: Adaptive and rolling Slow candidates, host/destination attribution, and Wazuh native XML temporal correlation (`111940–111948`). Ten controlled cases passed. See [`docs/data-exfiltration-validation-2026-10.md`](../docs/data-exfiltration-validation-2026-10.md) for test scope and limitations.

## Observability flow

```text
Network traffic -> Zeek ------------+
                                      |
Host events -----> Wazuh Agent ----> Wazuh Manager -> decoders/rules -> alerts
                                      |
                                      +-> Active Response (if enabled)
```

## Validation principle

Where available, positive tests are accompanied by negative controls or OFF/ON comparisons. Reduced evidence is stored under [`../evidence/`](../evidence/README.md).

For SSH, validation uses two sources and two victims to verify that correlation does not mix sessions from different pairs. For AppArmor, the same operation is compared between complain and enforce modes. For RouterOS, behavior is compared with Active Response disabled and enabled. For MITM, each vector is exercised separately and the final campaign should retain negative controls for normal ARP bindings, absence of rogue DHCP, and expected public DNS answers.

The ICMP Flood campaign first compared fixed (v1.4) and sliding (v1.5) windows with the **same PCAP** using raw mirrored observations; v1.7-rc2 adds path-specific, heuristic deduplication using `enforce`. The test data are summarized under [`../evidence/icmp-flood/`](../evidence/icmp-flood/README.md).
