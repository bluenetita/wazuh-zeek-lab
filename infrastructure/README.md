# Infrastructure

Questa directory contiene la documentazione relativa alle macchine virtuali che compongono l'infrastruttura interna del laboratorio.

L'obiettivo è descrivere il ruolo delle VM aziendali simulate, la loro posizione nella rete, il rapporto con Zeek/Wazuh e il loro utilizzo negli scenari di sicurezza.

## Obiettivo

La sezione `infrastructure/` documenta i sistemi interni del laboratorio, cioè le VM che simulano client, server e target aziendali.

Queste VM sono importanti perché:

* generano traffico legittimo;
* producono eventi host-based raccolti da Wazuh;
* comunicano attraverso le VLAN interne;
* partecipano agli scenari di attacco;
* permettono di confrontare visibilità network-based e host-based.

## VM documentate

| Directory         | VM        | Ruolo                                  | VLAN             |
| ----------------- | --------- | -------------------------------------- | ---------------- |
| `client-linux/`   | ClientVM  | Endpoint Linux interno                 | VLAN 20 - Client |
| `client-windows/` | WindowsVM | Endpoint Windows interno               | VLAN 20 - Client |
| `server-db/`      | ServerDB  | Server PostgreSQL interno              | VLAN 30 - Server |
| `victim-server/`  | VictimVM  | Server vulnerabile usato negli scenari | VLAN 30 - Server |

## Segmentazione di rete

Le VM interne sono distribuite principalmente su due VLAN operative.

| VLAN | Nome   | Sistemi principali  | Ruolo                   |
| ---: | ------ | ------------------- | ----------------------- |
|   20 | Client | ClientVM, WindowsVM | Endpoint utente         |
|   30 | Server | ServerDB, VictimVM  | Server interni e target |

La VLAN Monitoring è invece dedicata ai sistemi di osservabilità.

| VLAN | Nome       | Sistemi principali | Ruolo                    |
| ---: | ---------- | ------------------ | ------------------------ |
|   10 | Monitoring | ZeekVM, WazuhVM    | Monitoraggio e detection |

## Gateway e routing

Il routing tra le VLAN interne è gestito da RouterOS.

Ogni VM interna utilizza come gateway l'indirizzo RouterOS della propria VLAN.

| VLAN | Gateway RouterOS |
| ---: | ---------------- |
|   10 | `10.3.10.1`      |
|   20 | `10.3.20.1`      |
|   30 | `10.3.30.1`      |

Il traffico verso la rete esterna passa da:

```text id="ijxcrh"
VM interna
   |
   v
RouterOS
   |
   v
pfSense
   |
   v
Rete esterna simulata
```

## Relazione con Zeek

Zeek osserva il traffico generato dalle VM interne tramite mirroring configurato su Open vSwitch.

Le VM documentate in questa sezione possono generare evidenze nei log Zeek, ad esempio:

* connessioni tra client e server;
* traffico DNS;
* traffico HTTP;
* traffico TLS;
* tentativi SSH;
* traffico ICMP;
* download di payload;
* traffico di reverse shell;
* traffico di esfiltrazione.

## Relazione con Wazuh

Wazuh raccoglie eventi host-based dagli agent installati sulle VM monitorate.

Gli agent possono osservare:

* autenticazioni;
* log di sistema;
* modifiche al filesystem;
* eventi File Integrity Monitoring;
* processi e servizi;
* eventi Windows;
* log applicativi;
* alert generati da regole custom.

## Ruolo delle VM negli scenari

| Scenario             | VM coinvolte                          | Ruolo                                                                                 |
| -------------------- | ------------------------------------- | ------------------------------------------------------------------------------------- |
| Reverse Shell        | VictimVM, AttackerVM, ZeekVM, WazuhVM | VictimVM genera traffico verso AttackerVM; Zeek e Wazuh raccolgono evidenze           |
| Privilege Escalation | VictimVM                              | Attività locale osservabile principalmente da Wazuh                                   |

## Cosa documentare per ogni VM

Ogni sotto-directory dovrebbe includere almeno:

* ruolo della VM;
* sistema operativo;
* VLAN e indirizzo IP;
* gateway;
* servizi principali;
* configurazione Wazuh agent, se rilevante;
* relazione con Zeek;
* scenari in cui viene usata;
* note di sicurezza;
* cosa non versionare.

## Struttura consigliata per ogni VM

Ogni directory può seguire questa struttura minima:

```text id="zmlgv8"
<vm-name>/
└── README.md
```

Se in futuro servono configurazioni specifiche:

```text id="2qzkmi"
<vm-name>/
├── README.md
├── configs/
├── services/
└── notes.md
```

## Configurazioni da versionare

È possibile versionare:

* configurazioni sanificate;
* note sui servizi;
* configurazioni Wazuh agent se modificate;
* configurazioni applicative non sensibili;
* script di setup sicuri;
* esempi di log sanificati.

## Configurazioni da non versionare

Non caricare:

* password;
* token;
* chiavi private;
* certificati privati;
* dump database reali;
* dati personali;
* log completi;
* alert completi;
* payload;
* malware;
* file generati durante gli attacchi;
* configurazioni non sanificate.

## Note operative

Questa directory non deve essere usata come backup completo delle VM.

Deve servire a documentare:

* come sono configurate le VM;
* perché esistono nel laboratorio;
* quali eventi generano;
* come vengono osservate da Zeek e Wazuh;
* quali scenari supportano.

## Best practice

* mantenere ogni VM in una directory separata;
* documentare solo informazioni utili e sanificate;
* evitare duplicazioni inutili;
* collegare ogni VM agli scenari in cui viene usata;
* aggiornare la documentazione quando cambiano IP, servizi o ruoli;
* non versionare dati sensibili o file runtime.
