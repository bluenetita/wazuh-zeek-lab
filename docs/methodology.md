# Methodology

Questo documento descrive la metodologia utilizzata per progettare, simulare, osservare e documentare il cyber range.

## Obiettivo

L'obiettivo della metodologia è garantire che il laboratorio sia documentato in modo chiaro, riproducibile e sicuro.

La repository non ha lo scopo di distribuire exploit, payload o materiale offensivo, ma di documentare:

* architettura del laboratorio;
* configurazioni sanificate;
* flussi di rete;
* strumenti di monitoraggio;
* scenari simulati;
* evidenze raccolte;
* limiti osservati.

## Principi adottati

La documentazione segue alcuni principi principali:

| Principio       | Descrizione                                                              |
| --------------- | ------------------------------------------------------------------------ |
| Riproducibilità | Documentare configurazioni e flussi in modo ordinato                     |
| Separazione     | Tenere separati infrastruttura, blue team, red team, scenari ed evidenze |
| Sanificazione   | Rimuovere credenziali, token, IP sensibili e dati personali              |
| Sicurezza       | Non versionare payload, exploit, malware o log completi                  |
| Tracciabilità   | Collegare ogni scenario alle evidenze e ai componenti coinvolti          |
| Chiarezza       | Documentare solo ciò che è stato effettivamente implementato o simulato  |

## Approccio generale

Il lavoro è stato organizzato in più fasi.

```text
1. Progettazione dell'architettura
2. Configurazione della rete virtuale
3. Configurazione dei sistemi blue team
4. Configurazione della macchina red team
5. Simulazione degli scenari
6. Raccolta delle evidenze
7. Sanificazione e documentazione
```

## Fase 1 - Progettazione dell'architettura

La prima fase ha riguardato la definizione dell'infrastruttura del cyber range.

Sono stati identificati:

* host di virtualizzazione;
* segmenti di rete;
* firewall;
* router;
* sistemi di monitoraggio;
* macchina attaccante;
* endpoint e server interni;
* scenari da simulare.

L'architettura generale è documentata in:

```text
docs/architecture.md
```

## Fase 2 - Configurazione della rete

La rete è stata organizzata tramite Proxmox, Open vSwitch, pfSense e RouterOS.

Componenti principali:

| Componente   | Ruolo                                             |
| ------------ | ------------------------------------------------- |
| Proxmox      | Host di virtualizzazione                          |
| Open vSwitch | Bridge, VLAN e mirroring                          |
| pfSense      | Firewall tra rete esterna simulata e rete interna |
| RouterOS     | Routing inter-VLAN                                |

La rete è stata segmentata in VLAN dedicate, tra cui:

| VLAN | Ruolo             |
| ---: | ----------------- |
|   10 | Monitoring        |
|   20 | Client            |
|   30 | Server            |
|  999 | Mirror verso Zeek |

## Fase 3 - Configurazione Blue Team

La parte blue team è composta principalmente da Zeek e Wazuh.

### Zeek

Zeek è stato configurato per ricevere traffico mirrorato tramite Open vSwitch.

Zeek produce:

* log standard;
* log custom;
* evidenze network-based;
* eventi utili per Wazuh.

Documentazione correlata:

```text
blue-team/zeek/
```

### Wazuh

Wazuh è stato configurato per raccogliere eventi host-based e log custom Zeek.

Sono stati documentati:

* configurazione agent;
* decoder custom;
* rules custom;
* correlazioni;
* integrazione Zeek-Wazuh.

Documentazione correlata:

```text
blue-team/wazuh/
```

## Fase 4 - Configurazione Red Team

La parte red team è rappresentata da AttackerVM, basata su Kali Linux.

La macchina viene usata solo in ambiente isolato per generare attività controllata verso il target.

Documentazione correlata:

```text
red-team/
red-team/attacker-kali/
```

## Fase 5 - Simulazione degli scenari

La repository documenta solo gli scenari effettivamente simulati e validati.

| Scenario             | Stato      | Target       |
| -------------------- | ---------- | ------------ |
| Reverse Shell        | Completato | Client Linux |
| Privilege Escalation | Completato | Client Linux |

Gli scenari sono documentati in:

```text
scenarios/
```

## Reverse Shell

Lo scenario Reverse Shell è stato utilizzato per osservare una comunicazione controllata tra Client Linux e AttackerVM.

L'obiettivo era validare:

* visibilità di Zeek sul traffico di rete;
* generazione di log custom Zeek;
* raccolta dei log Zeek da parte di Wazuh;
* funzionamento di decoder e rules custom;
* correlazione degli eventi in Wazuh.

## Privilege Escalation

Lo scenario Privilege Escalation è stato utilizzato per osservare attività locali sul Client Linux.

L'obiettivo era evidenziare:

* importanza della telemetria host-based;
* ruolo di Wazuh nella visibilità locale;
* limiti di Zeek per attività che non generano traffico di rete;
* differenza tra osservabilità network-based e host-based.

## Fase 6 - Raccolta evidenze

Le evidenze sono state raccolte e separate dalla descrizione degli scenari.

```text
scenarios/   -> descrizione dello scenario
evidence/    -> evidenze sanificate osservate
```

Le evidenze possono includere:

* estratti Zeek ridotti;
* alert Wazuh sanificati;
* output sintetici;
* note di validazione;
* screenshot non sensibili.

Documentazione correlata:

```text
evidence/
```

## Fase 7 - Sanificazione

Prima di inserire contenuti nella repository, le configurazioni e le evidenze devono essere controllate e sanificate.

Non devono essere presenti:

* password;
* token;
* chiavi private;
* certificati privati;
* credenziali;
* payload;
* exploit;
* malware;
* reverse shell pronte all'uso;
* PCAP completi;
* log completi;
* dump database;
* dati personali.

## Placeholder utilizzati

Quando necessario, i dati reali vengono sostituiti con placeholder.

| Dato reale         | Placeholder         |
| ------------------ | ------------------- |
| IP AttackerVM      | `ATTACKER_IP`       |
| IP Client Linux    | `CLIENT_IP`         |
| IP ZeekVM          | `ZEEK_IP`           |
| IP WazuhVM         | `WAZUH_IP`          |
| Timestamp reale    | `TIMESTAMP`         |
| UID Zeek           | `UID`               |
| Hash reale         | `HASH_REDACTED`     |
| Hostname sensibile | `HOSTNAME_REDACTED` |
| Username reale     | `USER_REDACTED`     |
| Path sensibile     | `PATH_REDACTED`     |

## Controlli prima del commit

Prima di ogni commit è consigliato eseguire un controllo sui contenuti sensibili.

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|cvv|iban|payload|exploit" .
```

Controllare anche il diff:

```bash
git diff
```

Controllare lo stato della repository:

```bash
git status
```

## Separazione delle directory

La repository è organizzata per responsabilità.

| Directory         | Scopo                                   |
| ----------------- | --------------------------------------- |
| `docs/`           | Documentazione generale                 |
| `proxmox/`        | Virtualizzazione, bridge, OVS e routing |
| `network/`        | pfSense e RouterOS                      |
| `blue-team/`      | Zeek e Wazuh                            |
| `red-team/`       | AttackerVM / Kali                       |
| `infrastructure/` | VM interne                              |
| `scenarios/`      | Scenari simulati                        |
| `evidence/`       | Evidenze sanificate                     |

## Criteri di inclusione

Un file può essere incluso nella repository se:

* è utile alla documentazione;
* è sanificato;
* non contiene segreti;
* non contiene payload o exploit;
* non contiene log completi;
* aiuta a comprendere l'architettura o i risultati;
* è coerente con gli scenari realmente simulati.

## Criteri di esclusione

Un file non deve essere incluso se contiene:

* credenziali;
* token;
* chiavi;
* certificati privati;
* backup completi;
* snapshot;
* dischi virtuali;
* dump database;
* PCAP completi;
* log completi;
* exploit;
* payload;
* malware;
* output non controllati.

## Validazione degli scenari

Uno scenario viene considerato documentabile quando sono presenti:

* descrizione dello scenario;
* VM coinvolte;
* percorso del traffico o flusso logico;
* evidenze attese;
* evidenze osservate;
* limiti riscontrati;
* relazione con Zeek e/o Wazuh;
* indicazione dei file o componenti coinvolti.

## Gestione degli scenari non inclusi

La repository non include scenari non simulati o non validati.

Questa scelta evita ambiguità tra:

* attività pianificate;
* prove parziali;
* risultati effettivamente ottenuti.

## Ruolo di Zeek nella metodologia

Zeek viene utilizzato per osservare traffico di rete e generare log.

È particolarmente utile per:

* connessioni TCP;
* traffico persistente;
* traffico HTTP;
* log custom;
* eventi network-based;
* supporto alla correlazione con Wazuh.

## Ruolo di Wazuh nella metodologia

Wazuh viene utilizzato per raccogliere eventi host-based e generare alert.

È particolarmente utile per:

* log di sistema;
* autenticazioni;
* File Integrity Monitoring;
* eventi agent;
* decoder e rules custom;
* alert su log custom Zeek;
* correlazioni.

## Limiti metodologici

Il laboratorio presenta alcuni limiti da considerare:

| Limite                 | Impatto                                                |
| ---------------------- | ------------------------------------------------------ |
| Ambiente virtualizzato | Non rappresenta completamente una rete reale           |
| Traffico mirrorato     | Zeek vede solo traffico incluso nel mirror             |
| Attività locali        | Zeek non osserva direttamente eventi host-based        |
| Agent Wazuh            | La visibilità dipende dalla configurazione degli agent |
| Evidenze sanificate    | Alcuni dettagli reali vengono rimossi per sicurezza    |
| Scenari limitati       | Sono documentati solo gli scenari completati           |

## Best practice

* documentare solo ciò che è stato realmente implementato;
* separare scenari ed evidenze;
* mantenere le configurazioni sanificate;
* evitare comandi offensivi completi;
* non caricare payload o exploit;
* collegare ogni evidenza allo scenario corrispondente;
* indicare chiaramente i limiti osservati;
* mantenere coerenti README, docs e directory operative.

## Conclusione

La metodologia adottata punta a rendere il progetto chiaro, sicuro e verificabile.

Il valore principale della repository è documentare come un cyber range possa integrare infrastruttura virtualizzata, osservabilità network-based e osservabilità host-based per analizzare scenari controllati.
