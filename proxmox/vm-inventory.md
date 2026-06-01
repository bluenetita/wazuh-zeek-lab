# Proxmox VM Inventory

Questo documento descrive le macchine virtuali utilizzate nel laboratorio e il loro ruolo all'interno dell'infrastruttura simulata.

L'obiettivo è mantenere una vista sintetica e aggiornata degli asset virtuali presenti su Proxmox VE.

## Panoramica

| VM         | Ruolo                       | Sistema operativo                  | Categoria      |
| ---------- | --------------------------- | ---------------------------------- | -------------- |
| pfsense    | Firewall                    | pfSense / FreeBSD-based            | Network        |
| routeros   | Router inter-VLAN           | MikroTik RouterOS                  | Network        |
| ZeekVM     | Network Security Monitoring | Ubuntu Server 24.04.4              | Blue Team      |
| WazuhVM    | Host-Based Monitoring       | Ubuntu Server 24.04.4              | Blue Team      |
| ClientVM   | Endpoint Linux              | Ubuntu Server 24.04.4              | Infrastructure |
| WindowsVM  | Endpoint Windows            | Windows                            | Infrastructure |
| ServerDB   | Database Server             | Ubuntu Server 24.04.4 + PostgreSQL | Infrastructure |
| VictimVM   | Vulnerable Target           | Metasploitable3 Linux              | Infrastructure |
| AttackerVM | Attacker Machine            | Kali Linux                         | Red Team       |

## Risorse assegnate

| VM         |    CPU |  RAM | Storage | QEMU Agent | Firewall Proxmox |
| ---------- | -----: | ---: | ------: | ---------- | ---------------- |
| pfsense    | 1 vCPU | 1 GB |   10 GB | Abilitato  | Disabilitato     |
| routeros   | 1 vCPU | 1 GB |   10 GB | Abilitato  | Disabilitato     |
| ZeekVM     | 2 vCPU | 8 GB |   50 GB | Abilitato  | Disabilitato     |
| WazuhVM    | 2 vCPU | 8 GB |   50 GB | Abilitato  | Disabilitato     |
| ClientVM   | 1 vCPU | 4 GB |   50 GB | Abilitato  | Disabilitato     |
| WindowsVM  | 1 vCPU | 4 GB |   50 GB | Abilitato  | Disabilitato     |
| ServerDB   | 1 vCPU | 4 GB |   50 GB | Abilitato  | Disabilitato     |
| VictimVM   | 1 vCPU | 4 GB |   50 GB | Abilitato  | Disabilitato     |
| AttackerVM | 2 vCPU | 8 GB |   32 GB | Abilitato  | Disabilitato     |

## Distribuzione logica

| VM         | Segmento     | VLAN / Rete   | Descrizione                                      |
| ---------- | ------------ | ------------- | ------------------------------------------------ |
| ZeekVM     | Monitoring   | VLAN 10       | Sensore di rete per analisi traffico             |
| WazuhVM    | Monitoring   | VLAN 10       | Server Wazuh per monitoraggio host-based         |
| ClientVM   | Client       | VLAN 20       | Endpoint Linux interno                           |
| WindowsVM  | Client       | VLAN 20       | Endpoint Windows interno                         |
| ServerDB   | Server       | VLAN 30       | Server PostgreSQL interno                        |
| VictimVM   | Server       | VLAN 30       | Server vulnerabile usato come target controllato |
| AttackerVM | External     | vmbr1         | Macchina Kali Linux nella rete esterna simulata  |
| routeros   | Network Core | vmbr2 / vmbr3 | Router inter-VLAN e collegamento verso pfSense   |
| pfsense    | Firewall     | vmbr3 / vmbr1 | Firewall tra rete interna ed esterna             |

## Ruolo delle VM

### pfsense

pfSense è utilizzato come firewall tra la rete interna e la rete esterna simulata.

Funzioni principali:

* filtraggio del traffico;
* controllo delle comunicazioni in ingresso e in uscita;
* eventuale NAT;
* logging firewall;
* separazione tra infrastruttura interna e rete attaccante.

### routeros

RouterOS è utilizzato per il routing inter-VLAN.

Funzioni principali:

* gestione delle interfacce VLAN;
* gateway logico per le VLAN interne;
* routing tra VLAN 10, VLAN 20 e VLAN 30;
* inoltro del traffico verso pfSense tramite `vmbr3`.

### ZeekVM

ZeekVM è il sensore di rete del laboratorio.

Funzioni principali:

* analisi del traffico duplicato tramite mirroring/SPAN;
* generazione di log di rete;
* analisi di connessioni, DNS, HTTP, TLS e anomalie;
* esecuzione di script custom per detection avanzata;
* produzione di log custom per reverse shell e attività sospette.

### WazuhVM

WazuhVM è il server centrale per il monitoraggio host-based.

Funzioni principali:

* ricezione eventi dagli agent;
* analisi dei log di sistema;
* File Integrity Monitoring;
* decoder XML custom;
* regole XML custom;
* correlazione di eventi provenienti da Zeek e dagli host.

### ClientVM

ClientVM rappresenta un endpoint Linux interno.

Funzioni principali:

* simulazione di un host utente;
* generazione di traffico legittimo;
* partecipazione agli scenari di attacco;
* monitoraggio tramite Wazuh agent.

### WindowsVM

WindowsVM rappresenta un endpoint Windows interno.

Funzioni principali:

* simulazione di un host utente Windows;
* generazione di traffico legittimo;
* partecipazione agli scenari di attacco;
* monitoraggio tramite Wazuh agent.

### ServerDB

ServerDB è il server database interno basato su PostgreSQL.

Funzioni principali:

* simulazione di un servizio database aziendale;
* esposizione controllata di servizi interni;
* monitoraggio tramite Wazuh agent;
* analisi di eventuali tentativi di accesso o attività anomale.

### VictimVM

VictimVM è una macchina vulnerabile utilizzata come target controllato.

Funzioni principali:

* simulazione di un server vulnerabile;
* target per reverse shell;
* target per privilege escalation;
* target per ulteriori scenari offensivi;
* raccolta di evidenze tramite Wazuh agent.

### AttackerVM

AttackerVM è la macchina Kali Linux utilizzata per eseguire gli scenari di attacco.

Funzioni principali:

* generazione di traffico offensivo controllato;
* esecuzione di test di reverse shell;
* esecuzione di test di brute force;
* simulazione di attacchi MITM;
* simulazione di esfiltrazione dati;
* verifica della capacità di detection di Zeek e Wazuh.

## Note operative

* Tutte le VM sono ospitate su Proxmox VE.
* Il firewall Proxmox sulle singole VM è disabilitato.
* Il controllo del traffico è gestito principalmente tramite pfSense, RouterOS e la configurazione di rete virtuale.
* Le VLAN interne sono gestite su `vmbr2`, basato su Open vSwitch.
* Il traffico verso la rete esterna passa da RouterOS a pfSense tramite `vmbr3`.
* La rete esterna simulata è collegata a `vmbr1`.
* Zeek riceve traffico duplicato tramite mirroring configurato su Open vSwitch.
* Wazuh riceve eventi dagli agent installati sugli host monitorati.

## Campi da aggiornare

Quando disponibili, aggiungere:

| VM         | VM ID | IP  | MAC Address | Interfaccia Proxmox | Note |
| ---------- | ----: | --- | ----------- | ------------------- | ---- |
| pfsense    |   TBD | TBD | TBD         | TBD                 | TBD  |
| routeros   |   TBD | TBD | TBD         | TBD                 | TBD  |
| ZeekVM     |   TBD | TBD | TBD         | TBD                 | TBD  |
| WazuhVM    |   TBD | TBD | TBD         | TBD                 | TBD  |
| ClientVM   |   TBD | TBD | TBD         | TBD                 | TBD  |
| WindowsVM  |   TBD | TBD | TBD         | TBD                 | TBD  |
| ServerDB   |   TBD | TBD | TBD         | TBD                 | TBD  |
| VictimVM   |   TBD | TBD | TBD         | TBD                 | TBD  |
| AttackerVM |   TBD | TBD | TBD         | TBD                 | TBD  |
