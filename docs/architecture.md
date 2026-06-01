# Architecture

Questo documento descrive l'architettura generale del cyber range realizzato su Proxmox.

## Obiettivo

L'obiettivo dell'architettura è simulare un'infrastruttura aziendale controllata, composta da rete interna, rete esterna simulata, sistemi di monitoraggio e macchina attaccante.

Il laboratorio permette di osservare scenari di sicurezza attraverso:

* traffico di rete analizzato da Zeek;
* eventi host-based raccolti da Wazuh;
* routing inter-VLAN gestito da RouterOS;
* firewalling tra rete esterna e interna tramite pfSense;
* mirroring del traffico tramite Open vSwitch;
* evidenze sanificate raccolte durante gli scenari simulati.

## Panoramica generale

Il cyber range è composto da più livelli:

| Livello            | Componente              | Ruolo                                       |
| ------------------ | ----------------------- | ------------------------------------------- |
| Virtualizzazione   | Proxmox VE              | Ospita tutte le VM del laboratorio          |
| Switching virtuale | Open vSwitch            | Gestisce bridge, VLAN e mirror verso Zeek   |
| Firewall           | pfSense                 | Separa rete esterna simulata e rete interna |
| Routing            | RouterOS                | Gestisce routing inter-VLAN                 |
| Network monitoring | Zeek                    | Analizza traffico di rete mirrorato         |
| Host monitoring    | Wazuh                   | Raccoglie eventi host-based e genera alert  |
| Red team           | Kali Linux              | Macchina attaccante controllata             |
| Infrastructure     | Client e server interni | Sistemi target e servizi del laboratorio    |

## Schema logico

```text
AttackerVM / Kali
   |
   v
Rete esterna simulata
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
   +--> VLAN 10 - Monitoring
   |       +--> ZeekVM
   |       +--> WazuhVM
   |
   +--> VLAN 20 - Client
   |       +--> Client Linux / ClientVM
   |       +--> Client Windows / WindowsVM
   |
   +--> VLAN 30 - Server
           +--> ServerDB
           +--> Victim Server / Metasploitable3
```

## Componenti principali

### Proxmox VE

Proxmox VE è l'host di virtualizzazione del laboratorio.

Ospita le VM principali:

* pfSense;
* RouterOS;
* ZeekVM;
* WazuhVM;
* AttackerVM / Kali Linux;
* Client Linux;
* Client Windows;
* ServerDB;
* Victim Server / Metasploitable3.

La documentazione Proxmox si trova in:

```text
proxmox/
```

## Open vSwitch

Open vSwitch viene utilizzato su Proxmox per gestire il traffico interno e duplicarlo verso Zeek.

Il bridge principale è:

```text
vmbr2
```

OVS viene usato per:

* trasportare traffico VLAN;
* collegare VM interne e RouterOS;
* duplicare il traffico delle VLAN monitorate;
* inviare il traffico mirrorato verso Zeek tramite VLAN 999.

Documentazione correlata:

```text
proxmox/ovs/
proxmox/ovs-mirroring.md
proxmox/network-bridges.md
```

## Bridge Proxmox

| Bridge       | Ruolo                                                    |
| ------------ | -------------------------------------------------------- |
| `vmbr1`      | Rete esterna simulata, collegamento AttackerVM e pfSense |
| `vmbr2`      | Rete interna principale, VLAN e mirror OVS               |
| `vmbr3`      | Collegamento di transito tra RouterOS e pfSense          |
| `vmbr4-test` | Rete separata di test                                    |

## VLAN

| VLAN | Nome       | Ruolo                         |
| ---: | ---------- | ----------------------------- |
|   10 | Monitoring | ZeekVM e WazuhVM              |
|   20 | Client     | Client Linux e Client Windows |
|   30 | Server     | ServerDB e Victim Server      |
|  999 | Mirror     | Traffico duplicato verso Zeek |

## pfSense

pfSense agisce come firewall tra la rete esterna simulata e l'infrastruttura interna.

Nel laboratorio controlla il traffico tra:

```text
AttackerVM / Kali
   |
   v
pfSense
   |
   v
RouterOS
```

Documentazione correlata:

```text
network/pfsense/
```

## RouterOS

RouterOS gestisce il routing inter-VLAN e inoltra il traffico verso pfSense.

Le interfacce principali sono:

| Interfaccia RouterOS | Ruolo                                         |
| -------------------- | --------------------------------------------- |
| `ether1`             | Collegamento verso pfSense / rete di transito |
| `ether2`             | LAN / trunk VLAN interne                      |
| `ether3`             | Rete test                                     |

Gateway principali:

| VLAN / Rete | Gateway     |
| ----------- | ----------- |
| VLAN 10     | `10.3.10.1` |
| VLAN 20     | `10.3.20.1` |
| VLAN 30     | `10.3.30.1` |
| Rete test   | `10.5.0.1`  |

Documentazione correlata:

```text
network/routeros/
```

## Zeek

Zeek è il componente di Network Security Monitoring.

Riceve traffico duplicato tramite OVS mirror e produce:

* log standard;
* log custom;
* evidenze di rete;
* eventi utili per Wazuh.

I log custom principali sono:

```text
possible_malware.log
reverse_shell_live.log
reverse_shell_movement.log
reverse_shell_final.log
```

Documentazione correlata:

```text
blue-team/zeek/
```

## Wazuh

Wazuh è usato per host-based monitoring, alerting e correlazione.

Nel laboratorio Wazuh riceve:

* eventi dagli agent installati sugli host;
* log custom Zeek raccolti dall'agent su ZeekVM;
* eventi host-based dai sistemi monitorati.

Componenti Wazuh documentati:

* manager;
* agent configurations;
* decoder;
* rules;
* integrazione con Zeek;
* esempi di log e alert sanificati.

Documentazione correlata:

```text
blue-team/wazuh/
```

## Integrazione Zeek-Wazuh

Il flusso Zeek-Wazuh è:

```text
Traffico mirrorato
   |
   v
Zeek
   |
   v
Log standard / custom
   |
   v
Wazuh Agent su ZeekVM
   |
   v
Wazuh Manager
   |
   v
Decoder
   |
   v
Rules
   |
   v
Alert
```

Questa integrazione permette di generare alert Wazuh a partire da eventi osservati da Zeek.

## Red Team

La componente red team è rappresentata da:

```text
AttackerVM / Kali Linux
```

La macchina Kali si trova nella rete esterna simulata e viene usata per generare attività controllate nel cyber range.

Documentazione correlata:

```text
red-team/
red-team/attacker-kali/
```

## Target principale degli scenari

Il target principale degli scenari simulati è:

```text
Client Linux / ClientVM
```

Il Client Linux si trova nella VLAN Client ed è stato usato come target per gli scenari documentati.

Documentazione correlata:

```text
infrastructure/client-linux/
```

## Altri sistemi interni

| Sistema                         | Ruolo                                              |
| ------------------------------- | -------------------------------------------------- |
| Client Windows                  | Endpoint Windows interno                           |
| ServerDB                        | Server PostgreSQL interno                          |
| Victim Server / Metasploitable3 | Server vulnerabile documentato nell'infrastruttura |

Documentazione correlata:

```text
infrastructure/
```

## Scenari simulati

La repository documenta solo gli scenari effettivamente simulati e validati.

| Scenario             | Target       | Osservabilità principale |
| -------------------- | ------------ | ------------------------ |
| Reverse Shell        | Client Linux | Zeek e Wazuh             |
| Privilege Escalation | Client Linux | Wazuh                    |

Documentazione correlata:

```text
scenarios/
```

## Evidenze

Le evidenze raccolte durante gli scenari sono separate dalla descrizione degli scenari.

```text
scenarios/   -> descrizione dello scenario
evidence/    -> evidenze sanificate osservate
```

Le evidenze sono organizzate in:

```text
evidence/reverse-shell/
evidence/privilege-escalation/
```

## Percorso del traffico

### AttackerVM verso Client Linux

```text
AttackerVM / Kali
   |
   v
vmbr1
   |
   v
pfSense
   |
   v
RouterOS
   |
   v
VLAN 20 - Client
   |
   v
Client Linux
```

### Client Linux verso AttackerVM

```text
Client Linux
   |
   v
VLAN 20 - Client
   |
   v
RouterOS
   |
   v
pfSense
   |
   v
vmbr1
   |
   v
AttackerVM / Kali
```

## Percorso del traffico monitorato da Zeek

```text
Traffico VLAN 10 / 20 / 30
   |
   v
vmbr2 / Open vSwitch
   |
   +--> traffico originale
   |
   +--> copia su VLAN 999
           |
           v
        ZeekVM
```

## Ruolo dei componenti nella detection

| Componente | Visibilità                                            |
| ---------- | ----------------------------------------------------- |
| Zeek       | Traffico di rete, connessioni, log custom             |
| Wazuh      | Eventi host-based, alert, FIM, correlazioni           |
| pfSense    | Traffico permesso/bloccato tra rete esterna e interna |
| RouterOS   | Routing inter-VLAN e inoltro                          |
| OVS        | Mirroring del traffico verso Zeek                     |
| Proxmox    | Virtualizzazione e collegamento tra VM                |

## Separazione delle responsabilità

| Area                      | Directory         |
| ------------------------- | ----------------- |
| Architettura generale     | `docs/`           |
| Virtualizzazione e bridge | `proxmox/`        |
| Firewall e routing        | `network/`        |
| Monitoring e detection    | `blue-team/`      |
| Macchina attaccante       | `red-team/`       |
| Sistemi interni           | `infrastructure/` |
| Scenari simulati          | `scenarios/`      |
| Evidenze sanificate       | `evidence/`       |

## Sicurezza della repository

La repository non deve contenere:

* credenziali;
* token;
* chiavi private;
* payload;
* exploit;
* malware;
* reverse shell pronte all'uso;
* log completi;
* PCAP completi;
* dump database;
* backup VM;
* file runtime.

Le configurazioni presenti devono essere sanificate e usate a scopo documentale.

## Note finali

Questa architettura è progettata per documentare un ambiente di laboratorio isolato.

Il focus è sulla comprensione del flusso di rete, sull'integrazione tra Zeek e Wazuh e sulla validazione delle evidenze prodotte durante gli scenari simulati.
