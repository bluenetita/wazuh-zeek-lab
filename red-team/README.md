# Red Team

Questa directory contiene la documentazione relativa alla componente red team del laboratorio.

## Obiettivo

La sezione `red-team/` documenta l'infrastruttura attaccante utilizzata per generare scenari controllati all'interno del cyber range.

L'obiettivo non è pubblicare exploit, payload o materiale offensivo riutilizzabile, ma descrivere il ruolo della macchina attaccante, i percorsi di rete e gli scenari simulati in ambiente isolato.

## Componente principale

| Directory        | Componente              | Ruolo                                                     |
| ---------------- | ----------------------- | --------------------------------------------------------- |
| `attacker-kali/` | AttackerVM / Kali Linux | Macchina usata per simulare attività red team controllate |

## Ruolo nel laboratorio

La componente red team viene utilizzata per:

* generare traffico controllato;
* testare la raggiungibilità del target;
* simulare scenari di attacco in ambiente isolato;
* validare la visibilità di Zeek;
* validare gli alert Wazuh;
* verificare routing e firewalling;
* correlare evidenze network-based e host-based.

## Posizione nella rete

L'AttackerVM è collocata nella rete esterna simulata.

Percorso tipico verso l'infrastruttura interna:

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
VLAN Client
   |
   v
Client Linux
```

## Target principali

| Target                  | Ruolo                                            |
| ----------------------- | ------------------------------------------------ |
| Client Linux / ClientVM | Target principale degli scenari simulati         |
| AttackerVM / Kali Linux | Macchina usata per generare attività controllata |

## Scenari simulati

Nel laboratorio sono stati simulati e documentati due scenari principali:

| Scenario             | Stato      | Descrizione                                                                      |
| -------------------- | ---------- | -------------------------------------------------------------------------------- |
| Reverse Shell        | Completato | Simulazione controllata di una connessione dal Client Linux verso AttackerVM     |
| Privilege Escalation | Completato | Simulazione di attività post-compromissione e aumento privilegi sul Client Linux |

La repository documenta solo gli scenari effettivamente simulati e validati nel laboratorio.

## Reverse Shell

Lo scenario Reverse Shell è stato utilizzato per osservare:

* traffico di rete tra Client Linux e AttackerVM;
* connessioni persistenti;
* log custom generati da Zeek;
* alert generati da Wazuh;
* correlazione tra eventi Zeek e regole Wazuh custom.

Evidenze principali:

| Componente | Evidenza attesa                                                         |
| ---------- | ----------------------------------------------------------------------- |
| Zeek       | Connessione TCP, log custom reverse shell                               |
| Wazuh      | Alert custom basati sui log Zeek e/o eventi host-based sul Client Linux |
| pfSense    | Traffico permesso o bloccato tra rete interna ed esterna                |
| RouterOS   | Inoltro del traffico tra VLAN Client e rete esterna                     |

## Privilege Escalation

Lo scenario Privilege Escalation è stato utilizzato per osservare attività locali sul Client Linux.

Evidenze principali:

| Componente   | Evidenza attesa                                                 |
| ------------ | --------------------------------------------------------------- |
| Wazuh        | Eventi host-based, log di sistema, possibili eventi FIM         |
| Zeek         | Visibilità limitata, perché l'attività è principalmente locale  |
| Client Linux | Log locali, modifiche al sistema o attività post-compromissione |
| AttackerVM   | Origine dell'attività controllata                               |

## Ambito della documentazione

Questa sezione descrive esclusivamente le attività completate, osservate e documentate nel laboratorio.

Eventuali scenari non simulati o non validati non vengono inclusi nella repository, così da evitare ambiguità tra attività pianificate e risultati effettivamente ottenuti.

## Relazione con Zeek

Zeek osserva il traffico di rete generato dagli scenari quando attraversa il punto di mirroring configurato su Open vSwitch.

Nel contesto red team, Zeek è utile soprattutto per:

* osservare connessioni tra AttackerVM e Client Linux;
* analizzare durata e volume delle connessioni;
* identificare traffico HTTP o TCP sospetto;
* generare log custom per reverse shell;
* fornire eventi da inoltrare a Wazuh.

## Relazione con Wazuh

Wazuh osserva eventi host-based e riceve anche eventi derivati dai log custom Zeek.

Nel contesto red team, Wazuh è utile per:

* ricevere alert sugli host monitorati;
* correlare log Zeek custom;
* osservare attività locali sul Client Linux;
* rilevare eventi di File Integrity Monitoring;
* generare alert custom tramite rules XML.

## Directory correlate

| Directory                         | Descrizione                                  |
| --------------------------------- | -------------------------------------------- |
| `attacker-kali/`                  | Documentazione della macchina Kali           |
| `../scenarios/`                   | Documentazione degli scenari simulati        |
| `../blue-team/zeek/`              | Configurazione e log Zeek                    |
| `../blue-team/wazuh/`             | Configurazione Wazuh, decoder, rules e alert |
| `../infrastructure/client-linux/` | Documentazione del target Client Linux       |
| `../proxmox/ovs/`                 | Mirroring OVS verso Zeek                     |

## Cosa versionare

È possibile versionare:

* documentazione della macchina attaccante;
* note sugli scenari effettivamente svolti;
* comandi di verifica innocui;
* output ridotti e sanificati;
* evidenze sanificate;
* spiegazioni del flusso di attacco e detection.

## Cosa non versionare

Non caricare:

* exploit funzionanti;
* payload;
* malware;
* reverse shell pronte all'uso;
* credenziali;
* token;
* chiavi private;
* wordlist pesanti;
* dump;
* PCAP completi;
* file generati durante compromissioni;
* log completi non sanificati;
* script offensivi automatizzati.

## Note operative

La componente red team deve essere usata solo in ambiente controllato e isolato.

Questa directory documenta gli scenari svolti senza distribuire materiale offensivo riutilizzabile fuori contesto.

## Best practice

* documentare solo scenari realmente simulati;
* evitare di presentare attività non validate come risultati del progetto;
* non caricare payload o exploit;
* collegare ogni scenario alle evidenze Zeek e Wazuh;
* usare esempi sanificati;
* mantenere separata la documentazione red team dalle configurazioni blue team.
