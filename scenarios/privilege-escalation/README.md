# Privilege Escalation Scenario

Questa directory contiene la documentazione dello scenario di Privilege Escalation simulato nel cyber range.

## Obiettivo

Lo scenario ha l'obiettivo di documentare una fase post-compromissione controllata sul Client Linux, osservando quali evidenze vengono prodotte a livello host-based e quali limiti presenta la sola osservabilità di rete.

A differenza dello scenario Reverse Shell, la Privilege Escalation avviene principalmente sul sistema target. Per questo motivo Wazuh ha un ruolo più rilevante rispetto a Zeek.

## Stato

| Campo                 | Valore                  |
| --------------------- | ----------------------- |
| Scenario              | Privilege Escalation    |
| Stato                 | Completato              |
| Target                | Client Linux / ClientVM |
| Macchina di controllo | AttackerVM / Kali Linux |
| Ambiente              | Cyber range isolato     |
| Visibilità principale | Wazuh                   |
| Visibilità secondaria | Zeek                    |

## VM coinvolte

| VM                      | Ruolo                                                                   |
| ----------------------- | ----------------------------------------------------------------------- |
| AttackerVM / Kali Linux | Macchina usata per gestire l'attività controllata                       |
| Client Linux / ClientVM | Target dello scenario                                                   |
| WazuhVM                 | Raccolta eventi host-based e generazione alert                          |
| ZeekVM                  | Osservabilità network-based, con visibilità limitata in questo scenario |
| RouterOS                | Routing tra segmenti                                                    |
| pfSense                 | Firewall tra rete esterna simulata e rete interna                       |

## Target

Il target dello scenario è:

```text
Client Linux / ClientVM
```

Il Client Linux rappresenta un endpoint interno dell'infrastruttura aziendale simulata.

## Descrizione dello scenario

Lo scenario simula un'attività locale successiva alla compromissione iniziale del Client Linux.

L'obiettivo è verificare se le attività effettuate sul sistema target generano evidenze osservabili da Wazuh, ad esempio:

* eventi di sistema;
* attività utente;
* modifiche al filesystem;
* modifiche a permessi o file sensibili;
* possibili eventi File Integrity Monitoring;
* log locali;
* alert generati da regole Wazuh.

## Flusso logico

```text
AttackerVM / Kali
   |
   v
Interazione controllata con Client Linux
   |
   v
Attività locale sul sistema
   |
   v
Eventi host-based
   |
   v
Wazuh Agent
   |
   v
Wazuh Manager
   |
   v
Alert / evidenze
```

## Relazione con Zeek

Zeek ha visibilità limitata in questo scenario perché la Privilege Escalation avviene principalmente a livello locale sul Client Linux.

Zeek può osservare solo eventuale traffico di rete collegato allo scenario, ad esempio:

* connessioni tra AttackerVM e Client Linux;
* traffico di controllo precedente o successivo;
* eventuali download o trasferimenti;
* traffico generato durante la fase di accesso.

Tuttavia, Zeek non può osservare direttamente:

* comandi eseguiti localmente;
* cambio di privilegi;
* modifiche a file locali;
* creazione di utenti;
* modifica di permessi;
* attività sui processi locali.

## Relazione con Wazuh

Wazuh è il componente principale per l'osservabilità dello scenario.

Se l'agent Wazuh è installato sul Client Linux, può raccogliere evidenze come:

| Categoria      | Evidenza possibile                                   |
| -------------- | ---------------------------------------------------- |
| Log di sistema | Eventi generati dal sistema operativo                |
| Autenticazione | Accessi, sessioni, errori o eventi utente            |
| FIM            | Modifiche a file o directory monitorate              |
| Inventory      | Informazioni su pacchetti, processi e configurazioni |
| Alert          | Eventi generati da regole Wazuh                      |

## Evidenze attese

| Fonte         | Evidenza                                      |
| ------------- | --------------------------------------------- |
| Wazuh Agent   | Eventi locali dal Client Linux                |
| Wazuh Manager | Alert o eventi correlati                      |
| Log locali    | Tracce dell'attività sul sistema              |
| Zeek          | Eventuale traffico di rete correlato          |
| pfSense       | Eventuale traffico tra rete esterna e interna |
| RouterOS      | Inoltro del traffico verso la VLAN Client     |

## Evidenze ottenute

Questa sezione può essere compilata con risultati sanificati.

Esempio:

```text
- Wazuh ha raccolto eventi host-based dal Client Linux.
- Lo scenario ha evidenziato che le attività locali sono maggiormente visibili tramite Wazuh rispetto a Zeek.
- Zeek ha visibilità solo sul traffico di rete collegato allo scenario.
```

## Limiti osservati

La Privilege Escalation evidenzia una differenza importante tra osservabilità network-based e host-based.

| Componente  | Limite                                                       |
| ----------- | ------------------------------------------------------------ |
| Zeek        | Non vede attività locali senza traffico di rete              |
| Wazuh       | Richiede agent installato e configurato correttamente        |
| pfSense     | Vede solo traffico che attraversa il firewall                |
| RouterOS    | Vede/inoltra traffico, ma non eventi locali                  |
| Proxmox/OVS | Può duplicare traffico, ma non osserva attività host interne |

## Decoder e rules coinvolti

Per questo scenario possono essere rilevanti principalmente le regole Wazuh host-based.

Se sono state usate regole custom, documentarle qui.

| Tipo                 | File / Fonte          | Note                        |
| -------------------- | --------------------- | --------------------------- |
| Wazuh built-in rules | Regole standard Wazuh | Eventi host-based           |
| Wazuh FIM            | Syscheck / FIM        | Modifiche a file monitorati |
| Custom rules         | TBD                   | Da indicare se presenti     |

## Collegamenti con altre directory

| Directory                            | Descrizione                            |
| ------------------------------------ | -------------------------------------- |
| `../../red-team/attacker-kali/`      | Documentazione AttackerVM              |
| `../../infrastructure/client-linux/` | Documentazione del target Client Linux |
| `../../blue-team/wazuh/`             | Configurazione Wazuh                   |
| `../../blue-team/zeek/`              | Configurazione Zeek                    |
| `../../proxmox/`                     | Virtualizzazione e networking          |
| `../../network/routeros/`            | Routing inter-VLAN                     |
| `../../network/pfsense/`             | Firewall tra rete esterna e interna    |

## Cosa includere nella repository

È possibile includere:

* descrizione dello scenario;
* evidenze sanificate;
* alert Wazuh ridotti;
* note sui limiti osservati;
* riferimenti a regole o decoder;
* screenshot non sensibili;
* output sintetici.

## Cosa non includere

Non caricare:

* exploit;
* payload;
* malware;
* reverse shell pronte all'uso;
* comandi offensivi completi;
* credenziali;
* token;
* chiavi private;
* dump;
* file generati durante compromissioni;
* log completi non sanificati;
* PCAP completi.

## Note operative

Questo scenario deve essere documentato come attività svolta in ambiente isolato.

La documentazione deve concentrarsi sulle evidenze di detection e sui limiti osservati, non sulla riproduzione offensiva dettagliata della tecnica.

## Conclusioni

Lo scenario Privilege Escalation mostra che le attività locali sul Client Linux sono osservabili principalmente tramite Wazuh.

Zeek rimane utile per analizzare eventuale traffico di rete correlato, ma non può sostituire la telemetria host-based per attività eseguite localmente sul sistema target.
