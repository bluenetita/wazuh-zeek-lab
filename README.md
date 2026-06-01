# Cyber Range Zeek Wazuh

Repository di documentazione e configurazioni sanificate per un cyber range realizzato su Proxmox.

Il progetto simula una piccola infrastruttura aziendale e una rete attaccante, con l'obiettivo di osservare scenari di sicurezza tramite strumenti blue team come Zeek e Wazuh.

## Obiettivo del progetto

L'obiettivo del laboratorio è costruire un ambiente controllato in cui simulare attività offensive e analizzare le evidenze prodotte dai sistemi di monitoraggio.

Il cyber range permette di studiare:

* segmentazione di rete;
* routing inter-VLAN;
* firewalling tra rete interna ed esterna;
* mirroring del traffico verso Zeek;
* raccolta log e alert tramite Wazuh;
* correlazione tra eventi network-based e host-based;
* documentazione di configurazioni e risultati in modo riproducibile.

## Tecnologie principali

| Tecnologia             | Ruolo                                              |
| ---------------------- | -------------------------------------------------- |
| Proxmox VE             | Host di virtualizzazione                           |
| Open vSwitch           | Bridge virtuali e mirroring del traffico           |
| pfSense                | Firewall tra rete esterna simulata e rete interna  |
| RouterOS               | Routing inter-VLAN                                 |
| Zeek                   | Network Security Monitoring                        |
| Wazuh                  | Host-based monitoring, decoder, rules e alert      |
| Kali Linux             | Macchina red team / AttackerVM                     |
| PostgreSQL             | Database interno su ServerDB                       |
| Metasploitable3        | Server vulnerabile documentato nell'infrastruttura |
| Linux / Windows client | Endpoint interni del laboratorio                   |

## Architettura generale

Il laboratorio è composto da:

* infrastruttura di virtualizzazione Proxmox;
* rete esterna simulata;
* firewall pfSense;
* router RouterOS;
* VLAN interne;
* sistemi blue team;
* macchina attaccante;
* endpoint e server interni.

Schema logico semplificato:

```text
AttackerVM / Kali
   |
   v
pfSense
   |
   v
RouterOS
   |
   v
VLAN interne
   |
   +--> Client Linux
   +--> Client Windows
   +--> ServerDB
   +--> Victim Server

OVS mirror
   |
   v
ZeekVM
   |
   v
Wazuh
```

## Segmenti principali

| Segmento              | Descrizione                                             |
| --------------------- | ------------------------------------------------------- |
| Rete esterna simulata | Segmento in cui si trova AttackerVM                     |
| VLAN Monitoring       | Segmento dedicato a Zeek e Wazuh                        |
| VLAN Client           | Segmento degli endpoint client                          |
| VLAN Server           | Segmento dei server interni                             |
| VLAN Mirror           | Segmento usato per consegnare traffico mirrorato a Zeek |

## Scenari simulati

La repository documenta solo gli scenari effettivamente simulati e validati.

| Scenario             | Stato      | Target       | Evidenze principali                          |
| -------------------- | ---------- | ------------ | -------------------------------------------- |
| Reverse Shell        | Completato | Client Linux | Zeek custom logs, Wazuh alerts, correlazioni |
| Privilege Escalation | Completato | Client Linux | Evidenze host-based Wazuh                    |

## Repository structure

```text
cyber-range-zeek-wazuh/
├── README.md
├── .gitignore
├── docs/
├── proxmox/
├── network/
├── blue-team/
├── red-team/
├── infrastructure/
├── scenarios/
└── evidence/
```

## Directory principali

| Directory         | Descrizione                                                                            |
| ----------------- | -------------------------------------------------------------------------------------- |
| `docs/`           | Documentazione generale: architettura, metodologia, topologia, setup e troubleshooting |
| `proxmox/`        | Documentazione host Proxmox, bridge, OVS, routing e mirroring                          |
| `network/`        | Configurazioni e documentazione di pfSense e RouterOS                                  |
| `blue-team/`      | Configurazioni Zeek e Wazuh                                                            |
| `red-team/`       | Documentazione AttackerVM / Kali Linux                                                 |
| `infrastructure/` | Documentazione delle VM interne: client, server e target                               |
| `scenarios/`      | Documentazione degli scenari simulati                                                  |
| `evidence/`       | Evidenze sanificate raccolte durante gli scenari                                       |

## Proxmox

La directory `proxmox/` documenta il layer di virtualizzazione e networking.

Contiene:

* inventario VM;
* bridge di rete;
* note di routing;
* mirroring OVS;
* script e servizio systemd per rendere persistente il mirror verso Zeek;
* eventuali note nftables.

File principali:

```text
proxmox/README.md
proxmox/vm-inventory.md
proxmox/network-bridges.md
proxmox/ovs-mirroring.md
proxmox/routing.md
proxmox/ovs/
proxmox/nftables/
```

## Network

La directory `network/` documenta firewalling e routing.

Componenti principali:

| Directory           | Descrizione                                       |
| ------------------- | ------------------------------------------------- |
| `network/pfsense/`  | Configurazione e note pfSense                     |
| `network/routeros/` | Configurazione RouterOS, VLAN, routing e firewall |

RouterOS gestisce il routing inter-VLAN, mentre pfSense controlla il traffico tra rete interna e rete esterna simulata.

## Blue Team

La directory `blue-team/` contiene configurazioni e documentazione dei sistemi di monitoraggio.

| Directory          | Descrizione                                                        |
| ------------------ | ------------------------------------------------------------------ |
| `blue-team/zeek/`  | Configurazione Zeek, script custom, logrotate, systemd e netplan   |
| `blue-team/wazuh/` | Configurazione Wazuh, agent, decoder, rules, integrazioni e sample |

## Zeek

Zeek viene usato per osservare il traffico mirrorato tramite Open vSwitch.

Elementi documentati:

* configurazione di rete;
* servizi systemd;
* log custom;
* logrotate;
* script Zeek;
* esempi di log;
* integrazione con Wazuh.

I log custom principali includono:

```text
possible_malware.log
reverse_shell_live.log
reverse_shell_movement.log
reverse_shell_final.log
```

## Wazuh

Wazuh viene usato per raccogliere eventi host-based e log Zeek custom.

Elementi documentati:

* configurazione agent Zeek;
* decoder Zeek standard e custom;
* rules custom;
* correlazioni reverse shell;
* integrazione Zeek-Wazuh;
* esempi di alert sanificati.

## Red Team

La directory `red-team/` documenta la macchina attaccante.

| Directory                         | Descrizione                                     |
| --------------------------------- | ----------------------------------------------- |
| `red-team/attacker-kali/`         | Documentazione Kali / AttackerVM                |
| `red-team/attacker-kali/network/` | Configurazione di rete sanificata della VM Kali |

La documentazione red team non include payload, exploit o materiale offensivo riutilizzabile.

## Infrastructure

La directory `infrastructure/` documenta le VM interne del laboratorio.

| Directory         | VM                      | Ruolo                                        |
| ----------------- | ----------------------- | -------------------------------------------- |
| `client-linux/`   | Client Linux / ClientVM | Target principale degli scenari simulati     |
| `client-windows/` | WindowsVM               | Endpoint Windows interno                     |
| `server-db/`      | ServerDB                | Server PostgreSQL interno                    |
| `victim-server/`  | VictimVM                | Server vulnerabile basato su Metasploitable3 |

## Scenarios

La directory `scenarios/` contiene la descrizione degli scenari simulati.

| Directory                         | Scenario             |
| --------------------------------- | -------------------- |
| `scenarios/reverse-shell/`        | Reverse Shell        |
| `scenarios/privilege-escalation/` | Privilege Escalation |

Ogni scenario documenta:

* obiettivo;
* VM coinvolte;
* percorso del traffico;
* evidenze attese;
* evidenze osservate;
* relazione con Zeek e Wazuh;
* limiti osservati;
* note di sicurezza.

## Evidence

La directory `evidence/` contiene evidenze ridotte e sanificate.

| Directory                              | Evidenze                                               |
| -------------------------------------- | ------------------------------------------------------ |
| `evidence/reverse-shell/zeek/`         | Evidenze Zeek relative alla reverse shell              |
| `evidence/reverse-shell/wazuh/`        | Alert e correlazioni Wazuh relative alla reverse shell |
| `evidence/privilege-escalation/wazuh/` | Evidenze Wazuh relative alla privilege escalation      |

Le evidenze complete, i log grezzi e i PCAP completi non vengono versionati.

## Cosa è incluso

La repository include:

* documentazione dell'architettura;
* configurazioni sanificate;
* script di supporto sicuri;
* esempi di configurazione;
* decoder e rules Wazuh custom;
* note operative;
* evidenze ridotte e sanificate;
* documentazione degli scenari completati.

## Cosa non è incluso

La repository non include:

* credenziali;
* token;
* chiavi private;
* certificati privati;
* payload;
* exploit;
* malware;
* reverse shell pronte all'uso;
* PCAP completi;
* log completi;
* dump database;
* backup VM;
* dischi virtuali;
* snapshot Proxmox;
* file runtime;
* dati personali.

## Sicurezza e sanificazione

Prima di ogni commit è consigliato controllare che non siano presenti dati sensibili.

Esempio:

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|cvv|iban|payload|exploit" .
```

Controllare anche il diff:

```bash
git diff
```

## Note operative

Questa repository non è un backup completo dell'infrastruttura.

È una raccolta documentata e sanificata di:

* configurazioni rilevanti;
* decisioni architetturali;
* procedure operative;
* scenari simulati;
* evidenze ridotte.

## Best practice adottate

* separazione tra documentazione, configurazioni ed evidenze;
* sanificazione dei dati sensibili;
* esclusione di log completi e payload;
* documentazione degli scenari realmente simulati;
* collegamento tra red team, blue team e infrastruttura;
* uso di README dedicati per ogni componente;
* tracciamento delle configurazioni più importanti.

## Stato del progetto

Il progetto documenta una versione funzionante del cyber range con:

* infrastruttura virtualizzata su Proxmox;
* routing e firewalling tramite RouterOS e pfSense;
* mirroring OVS verso Zeek;
* raccolta e alerting tramite Wazuh;
* simulazione di Reverse Shell;
* simulazione di Privilege Escalation;
* evidenze sanificate dei risultati osservati.
