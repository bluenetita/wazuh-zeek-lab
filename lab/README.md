# Cyber Range Zeek + Wazuh

Repository di documentazione, configurazioni sanificate ed evidenze ridotte relative a un cyber range virtualizzato su Proxmox. Il laboratorio integra **Zeek** per la visibilità di rete, **Wazuh** per raccolta, normalizzazione, correlazione e risposta, **RouterOS** per routing/containment e **AppArmor** per il controllo applicativo sul server vulnerabile.

## Obiettivo

Il progetto nasce per verificare, in un ambiente controllato, quanto sia utile combinare segnali network-based e host-based durante scenari di sicurezza reali del laboratorio. Le configurazioni pubblicate sono quelle rilevanti per la riproducibilità del lavoro; credenziali, chiavi private, webhook funzionanti, PCAP completi e log grezzi non vengono versionati.

## Architettura logica

```text
Rete esterna / AttackerVM
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
             +-- Client-Linux2 (validazione SSH)

Mirror OVS delle VLAN -> VLAN 999 -> ZeekVM -> Wazuh
```

Per la validazione multi-host SSH sono stati usati due endpoint sorgente e due server:

| Ruolo | Host | IP di laboratorio |
|---|---|---|
| A1 | Client-Linux | `10.3.20.2` |
| A2 | Client-Linux2 | `10.3.20.4` |
| V1 | ServerDB | `10.3.30.3` |
| V2 | ServerDB2 | `10.3.30.4` |

I due cloni aggiuntivi servono soprattutto alla validazione delle correlazioni e non introducono una nuova architettura applicativa. Dettagli: [`docs/topology-ssh-validation-2026-10.md`](docs/topology-ssh-validation-2026-10.md).

## Componenti principali

| Componente | Ruolo |
|---|---|
| Proxmox VE | Virtualizzazione del cyber range |
| Open vSwitch | Bridge e mirroring del traffico |
| pfSense | Firewall verso la rete esterna simulata |
| RouterOS | Routing inter-VLAN e containment tramite address-list |
| Zeek | Network Security Monitoring e detector custom |
| Wazuh | Raccolta host/network, decoder, regole, correlazioni e Active Response |
| AppArmor | Mitigazione del servizio inventario su ServerDB |
| Auditd | Telemetria host usata nelle correlazioni reverse shell/privilege escalation |

## Scenari documentati

| Scenario | Stato | Evidenze principali |
|---|---|---|
| [Reverse shell](scenarios/reverse-shell/README.md) | Validato | Zeek live/movement, Auditd/Wazuh, correlazioni cross-source |
| [Privilege escalation](scenarios/privilege-escalation/README.md) | Validato | Eventi host-based e regole Wazuh |
| [Network scanning](scenarios/network-scanning/README.md) | Validato | Detector Zeek e regole Wazuh di scanning |
| [AppArmor mitigation](scenarios/apparmor-mitigation/README.md) | Validato | 5 complain + 5 enforce della serie finale servicefix |
| [Active Response RouterOS](scenarios/active-response/README.md) | Validato | 5 prove OFF + 5 ON con quarantena e probe |
| [SSH brute force / Endpoint Normalizer](scenarios/ssh-bruteforce/README.md) | Validato | Pair correlation, mismatch, fan-out `120940`, fan-in `120941` |

La repository non presenta come completati scenari per cui non sono incluse evidenze sufficienti in questo snapshot.

## Risultati recenti

### SSH Endpoint Normalizer

La correlazione SSH usa la coppia ordinata **attacker -> victim**, non soltanto la sorgente. L'endpoint arricchisce i log `sshd` con `wazuh_dst_ip=$(host_ip)`; i decoder espongono sia i campi statici `srcip`/`dstip` sia gli alias dinamici `src_ip`/`dest_ip`.

Sono stati verificati:

- stessa coppia: correlazione positiva;
- stessa sorgente ma destinazione diversa: nessuna chiusura errata della catena di successo;
- sorgente diversa ma stessa destinazione: nessuna chiusura errata della catena;
- fan-out A1->V1 + A1->V2: `120940`;
- fan-in A1->V1 + A2->V1: `120941`;
- A1->V1 + A2->V2: due coppie indipendenti, senza falso fan-out/fan-in.

### AppArmor

La serie finale `servicefix` contiene 5 coppie complain/enforce. L'esecuzione di `/usr/bin/dash` risulta consentita in complain e negata in enforce; nelle prove enforce sono presenti gli alert Wazuh previsti. Il servizio rimane attivo e con PID invariato nella serie finale.

### Active Response RouterOS

La campagna include 5 prove con Active Response disabilitata e 5 abilitate. Nelle prove ON sono presenti invocazione AR, membership nella address-list `Quarantine` e fallimento del probe di connettività previsto; nelle prove OFF questi indicatori non compaiono. La configurazione pubblicata mantiene la quarantena automatica commentata nel Manager: la repository documenta la funzione senza abilitarla implicitamente.

## Struttura della repository

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

- [`blue-team/zeek/`](blue-team/zeek/README.md): configurazione Zeek, script custom e logging.
- [`blue-team/wazuh/`](blue-team/wazuh/README.md): agent, decoder, regole, correlazioni e Active Response.
- `blue-team/apparmor/`: profilo AppArmor del servizio inventario.

### Infrastructure

La directory [`infrastructure/`](infrastructure/README.md) descrive gli endpoint e i server interni. `ServerDB2` e `Client-Linux2` sono cloni usati per la validazione multi-host SSH. La vecchia directory `victim-server/` viene mantenuta come documentazione storica e non rappresenta il target principale delle validazioni recenti.

### Evidence

[`evidence/`](evidence/README.md) contiene soltanto evidenze ridotte e sanificate: alert selezionati, estratti di log, risultati dei test e tabelle. Non è un archivio completo dei log del laboratorio.

## File principali dell'aggiornamento

### Zeek

```text
blue-team/zeek/site/local.zeek
blue-team/zeek/site/custom_scripts/reverse_shell/reverse_shell_movement.zeek
blue-team/zeek/site/custom_scripts/scanning/address_scan.zeek
blue-team/zeek/site/custom_scripts/ssh_bruteforce/ssh_bruteforce.zeek
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
```

### Active Response e AppArmor

```text
blue-team/wazuh/active-response/routeros_quarantine.py
blue-team/wazuh/active-response/routeros.conf.example
blue-team/wazuh/active-response/collect_reverse_shell_evidence.sh
blue-team/apparmor/profiles/opt.inventario_service.inventario_c
infrastructure/server-db/inventario-service/
```

## Sanificazione

Non vengono pubblicati:

- `client.keys`, `authd.pass`;
- chiavi SSH private;
- password e token;
- webhook firmati;
- configurazioni RouterOS contenenti credenziali;
- PCAP completi e log grezzi integrali;
- payload, malware o exploit riutilizzabili;
- backup e snapshot delle VM.

Il webhook presente nell'export del Manager è sostituito da un placeholder.

## Note sui limiti

Questo repository descrive un **laboratorio sperimentale**, non una baseline di produzione. Le soglie Zeek, le finestre Wazuh e la policy RouterOS sono state scelte per il cyber range e devono essere rivalutate prima di un utilizzo operativo. In particolare, i test fan-out/fan-in SSH sono sequenziali e sono stati distanziati per non interferire con l'`ignore` della regola stock Wazuh.

## Licenza

GPL-3.0. Vedere [`LICENSE`](LICENSE).
