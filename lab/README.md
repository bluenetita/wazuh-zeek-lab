# Zeek + Wazuh Cyber Range

Repository containing documentation, sanitized configurations, and reduced evidence for a cyber range virtualized on Proxmox. The lab integrates **Zeek** for network visibility, **Wazuh** for collection, normalization, correlation, and response, **RouterOS** for routing and containment, and **AppArmor** for application-level control on the vulnerable server.

## Objective

The project evaluates, in a controlled environment, the value of combining network-based and host-based signals across realistic lab security scenarios. The repository contains the configurations relevant to reproducibility; credentials, private keys, live webhooks, full PCAPs, and complete raw logs are not versioned.

## Logical architecture

```text
External network / AttackerVM
          |
       pfSense
          |
       RouterOS
          |
   +------+------+----------------+
   |             |                |
VLAN 10       VLAN 20          VLAN 30
Monitoring    Client           Server
   |          |   |            |    |
Wazuh      Client  Windows   ServerDB ...
Zeek       Linux
             |
             +-- Client-Linux2 (SSH validation)

OVS mirror of VLANs -> VLAN 999 -> ZeekVM -> Wazuh
```
Two source endpoints and two servers were used for multi-host SSH validation:

| Role | Host | Lab IP |
|---|---|---|
| A1 | Client-Linux | `10.3.20.2` |
| A2 | Client-Linux2 | `10.3.20.4` |
| V1 | ServerDB | `10.3.30.3` |
| V2 | ServerDB2 | `10.3.30.4` |

The two additional clones are used mainly to validate correlation behavior and do not introduce a new application architecture. See [`docs/topology-ssh-validation-2026-10.md`](docs/topology-ssh-validation-2026-10.md).

## Main components

| Component | Role |
|---|---|
| Proxmox VE | Cyber-range virtualization |
| Open vSwitch | Bridging and traffic mirroring |
| pfSense | Firewall toward the simulated external network |
| RouterOS | Inter-VLAN routing and containment through an address list |
| Zeek | Network Security Monitoring and custom detectors |
| Wazuh | Host/network collection, decoders, rules, correlations, and Active Response |
| AppArmor | Mitigation for the inventory service on ServerDB |
| Auditd | Host telemetry used in reverse-shell and privilege-escalation correlations |

## Documented scenarios

| Scenario | Status | Main evidence |
|---|---|---|
| [Reverse shell](scenarios/reverse-shell/README.md) | Validated | Zeek live/movement, Auditd/Wazuh, cross-source correlations |
| [Privilege escalation](scenarios/privilege-escalation/README.md) | Validated | Host-based events and Wazuh rules |
| [Network scanning](scenarios/network-scanning/README.md) | Validated | Zeek scanning detectors and Wazuh rules |
| [AppArmor mitigation](scenarios/apparmor-mitigation/README.md) | Validated | 5 complain + 5 enforce runs from the final servicefix series |
| [RouterOS Active Response](scenarios/active-response/README.md) | Validated | 5 OFF + 5 ON runs with quarantine and connectivity probe |
| [SSH brute force / Endpoint Normalizer](scenarios/ssh-bruteforce/README.md) | Validated | Pair correlation, mismatch tests, fan-out `120940`, fan-in `120941` |
| [MITM / Adversary-in-the-Middle](scenarios/mitm/README.md) | Validated (positive Zeek path) | ARP, rogue DHCP, and DNS-spoofing indicators; Wazuh rules `100930-100932` |
| [ICMP Echo Flood](scenarios/icmp-flood/README.md) | Functionally validated (v1.7-rc2) | Protected subnets, sliding window, topology-specific OVS TTL-pair deduplication, Wazuh `100940` |
| [Data Exfiltration](scenarios/data-exfiltration/README.md) | Validated (10/10 controlled cases, 28 Oct 2026) | Adaptive/Slow TCP flow-volume detection, native XML `111940–111948`, no Active Response |
The repository does not mark scenarios as completed when this snapshot does not contain enough supporting evidence.

## Recent results

### SSH Endpoint Normalizer

SSH correlation uses the ordered **attacker -> victim** pair rather than only the source address. The endpoint enriches `sshd` logs with `wazuh_dst_ip=$(host_ip)`; the decoders expose both static `srcip`/`dstip` fields and dynamic `src_ip`/`dest_ip` aliases.

The following cases were verified:
- same pair: positive correlation;
- same source, different destination: no incorrect completion of the success chain;
- different source, same destination: no incorrect completion of the chain;
- fan-out A1->V1 + A1->V2: `120940`;
- fan-in A1->V1 + A2->V1: `120941`;
- A1->V1 + A2->V2: two independent pairs without false fan-out/fan-in.

### AppArmor

The final `servicefix` series contains 5 complain/enforce pairs. Execution of `/usr/bin/dash` is allowed in complain mode and denied in enforce mode; the expected Wazuh alerts are present in the enforce runs. The service remains active and the Main PID stays unchanged in the final series.

### RouterOS Active Response

The campaign contains 5 runs with Active Response disabled and 5 with it enabled. In the ON runs, the AR invocation, membership in the `Quarantine` address list, and the expected connectivity-probe failure were observed; these indicators were absent in the OFF runs. The published Manager configuration keeps automatic quarantine commented out: the repository documents the feature without enabling it implicitly.

### MITM / Adversary-in-the-Middle

The VLAN 20 campaign adds separate Zeek detections for protected IP/MAC mismatches, unexpected DHCP server responses on the static segment, and protected public DNS names returning private IPv4 answers. Reduced positive-path Zeek evidence is published under `evidence/mitm/`; reusable operational attack commands and full raw logs remain outside the public repository.

### ICMP Echo Flood: final v1.7-rc2 lab stage

The detector tracks destinations in the three approved internal /24 networks, with an exact sliding window (500 *estimated distinct* Echo Request observations in less than 5 s), separate cooldown per destination, and bounded inactive-state expiry. The lab's OVS route mirrors both pre- and post-routing copies; a one-to-one TTL-decrement matching heuristic (`64 -> 63`, strictly under 2 ms) can exclude likely mirror copies in `enforce` mode. Wazuh rule `100940` ingests the corresponding `icmp_flood.log` JSON events without asserting the attacker identity. This is **experimental and path-specific**; it does not establish actual denial of service.

See the [scenario](scenarios/icmp-flood/README.md), [current Zeek module](blue-team/zeek/site/custom_scripts/icmp_flood/README.md), [technical validation](docs/icmp-flood-validation-2026-10.md), and [reduced October 2026 evidence](evidence/icmp-flood/README.md).

### Data Exfiltration: final 28 October 2026 validation

The completed-flow Zeek implementation produces one `data_exfiltration.log` JSON stream. Adaptive destination/host and rolling Slow destination/host detections are classified by native Wazuh XML rules `111940–111948`, including repeated candidate and Slow persistence correlation. **10/10 controlled post-migration cases passed**, including independent-source isolation, trained baseline, and log rotation/restart recovery. This is a detection-only scenario, not proof of confidential data theft. Full logs are held privately; only sanitized/reduced summaries are published.

See the [scenario](scenarios/data-exfiltration/README.md), [technical validation](docs/data-exfiltration-validation-2026-10.md), and [reduced results](evidence/data-exfiltration/README.md).

## Repository structure

```text
wazuh-zeek-lab/
├── README.md
├── blue-team/
│   ├── apparmor/
│   ├── wazuh/
│   └── zeek/
├── docs/
├── evidence/
├── infrastructure/
├── network/
├── proxmox/
├── red-team/
└── scenarios/
```

### Blue Team

- [`blue-team/zeek/`](blue-team/zeek/README.md): Zeek configuration, custom scripts, and logging.
- [`blue-team/wazuh/`](blue-team/wazuh/README.md): agents, decoders, rules, correlations, and Active Response.
- `blue-team/apparmor/`: AppArmor profile for the inventory service.

### Infrastructure

The [`infrastructure/`](infrastructure/README.md) directory describes internal endpoints and servers. `ServerDB2` and `Client-Linux2` are clones used for multi-host SSH validation. The older `victim-server/` directory is retained as historical documentation and is not the primary target of the latest validations.

### Evidence

[`evidence/`](evidence/README.md) contains only reduced and sanitized evidence: selected alerts, log excerpts, test results, and tables. It is not a complete archive of laboratory logs.

## Selected versioned configuration files

### Zeek

```text
blue-team/zeek/site/local.zeek
blue-team/zeek/site/custom_scripts/reverse_shell/reverse_shell_movement.zeek
blue-team/zeek/site/custom_scripts/scanning/address_scan.zeek
blue-team/zeek/site/custom_scripts/ssh_bruteforce/ssh_bruteforce.zeek
blue-team/zeek/site/custom_scripts/mitm/
blue-team/zeek/site/custom_scripts/icmp_flood/ (__load__.zeek, config.zeek, dedup.zeek, icmp_flood.zeek)
blue-team/zeek/site/custom_scripts/data_exfiltration/ (__load__.zeek, connection.zeek, window.zeek, adaptive.zeek, slow.zeek, config.zeek)
```

### Wazuh

```text
blue-team/wazuh/manager/ossec.conf
blue-team/wazuh/agent-configs/*.conf
blue-team/wazuh/decoders/000_audit_saddr_decoder.xml
blue-team/wazuh/decoders/010_zeek_ssh_pair_decoder.xml
blue-team/wazuh/decoders/0310-ssh_decoders.xml
blue-team/wazuh/rules/002_zeek_rules_custom.xml
blue-team/wazuh/rules/004_zeek_auditd_correlation.xml
blue-team/wazuh/rules/005_zeek_scanning_correlation.xml
blue-team/wazuh/rules/9999_ssh_bruteforce_correlation.xml
blue-team/wazuh/rules/007_mitm_rules.xml
blue-team/wazuh/rules/008_zeek_icmp_flood_rules.xml
blue-team/wazuh/rules/097_zeek_exfil_rules.xml
blue-team/wazuh/rules/098_zeek_exfil_slow_persistence_rules.xml
```

### Active Response and AppArmor

```text
blue-team/wazuh/active-response/routeros_quarantine.py
blue-team/wazuh/active-response/routeros.conf.example
blue-team/wazuh/active-response/collect_reverse_shell_evidence.sh
blue-team/apparmor/profiles/opt.inventario_service.inventario_c
infrastructure/server-db/inventario-service/
```

## Sanitization

The following are not published:

- `client.keys`, `authd.pass`;
- private SSH keys;
- passwords and tokens;
- signed webhooks;
- RouterOS configurations containing credentials;
- full PCAPs and complete raw logs;
- reusable payloads, malware, or exploits;
- VM backups and snapshots.

The webhook present in the Manager export has been replaced with a placeholder.

## Limitations

This repository documents an **experimental laboratory**, not a production baseline. Zeek thresholds, Wazuh windows, and the RouterOS policy were selected for the cyber range and must be reassessed before operational use. In particular, the SSH fan-out/fan-in tests were sequential and were spaced apart to avoid interference from the stock Wazuh rule `ignore` interval.

## License

GPL-3.0. See [`LICENSE`](LICENSE).
