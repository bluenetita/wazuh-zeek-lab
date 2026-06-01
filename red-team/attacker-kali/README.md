# Attacker Kali

Questa directory contiene la documentazione relativa alla macchina attaccante utilizzata nel laboratorio.

## Ruolo nel laboratorio

`AttackerVM` rappresenta la macchina utilizzata per simulare attività red team controllate all'interno del cyber range.

Nel laboratorio è basata su Kali Linux ed è utilizzata esclusivamente in ambiente isolato per validare la visibilità di Zeek e Wazuh durante gli scenari simulati.

## Posizione nella rete

| Campo          | Valore                |
| -------------- | --------------------- |
| Nome VM        | `AttackerVM`          |
| Sistema        | Kali Linux            |
| Ruolo          | Macchina attaccante   |
| Segmento       | Rete esterna simulata |
| Bridge Proxmox | `vmbr1`               |

## Percorso verso la rete interna

Il traffico generato da AttackerVM verso i sistemi interni attraversa pfSense e RouterOS.

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
VLAN interne
```

## Target principale

Nel laboratorio, il target principale degli scenari red team eseguiti è stato il client Linux interno.

| Target                  | Ruolo                                                           |
| ----------------------- | --------------------------------------------------------------- |
| Client Linux / ClientVM | Endpoint Linux interno usato come target degli scenari simulati |

## Scenari simulati

Gli scenari effettivamente simulati con AttackerVM sono:

| Scenario             | Stato      | Ruolo di AttackerVM                                                   |
| -------------------- | ---------- | --------------------------------------------------------------------- |
| Reverse Shell        | Completato | Host esterno coinvolto nella connessione controllata con Client Linux |
| Privilege Escalation | Completato | Macchina da cui viene gestita l'attività controllata sul Client Linux |

La documentazione di questa directory si limita agli scenari realmente eseguiti e validati.

## Reverse Shell

Nello scenario Reverse Shell, AttackerVM viene usata come macchina esterna coinvolta nella comunicazione con Client Linux.

L'obiettivo dello scenario è osservare:

* connessioni tra Client Linux e AttackerVM;
* traffico persistente;
* eventi custom generati da Zeek;
* alert generati da Wazuh;
* correlazione tra traffico di rete e detection.

Evidenze attese:

| Componente | Evidenza                                                               |
| ---------- | ---------------------------------------------------------------------- |
| Zeek       | Connessioni TCP e log custom reverse shell                             |
| Wazuh      | Alert generati da regole custom e/o eventi host-based sul Client Linux |
| pfSense    | Eventuale traffico permesso/bloccato tra rete interna ed esterna       |
| RouterOS   | Inoltro del traffico tra VLAN Client e rete esterna                    |

## Privilege Escalation

Nello scenario Privilege Escalation, AttackerVM viene usata come macchina di controllo per interagire con Client Linux in ambiente isolato.

L'obiettivo dello scenario è osservare attività locali sul Client Linux.

Evidenze attese:

| Componente   | Evidenza                                                       |
| ------------ | -------------------------------------------------------------- |
| Wazuh        | Eventi host-based, log locali, possibili eventi FIM            |
| Zeek         | Visibilità limitata, perché l'attività è principalmente locale |
| Client Linux | Modifiche o eventi locali                                      |
| AttackerVM   | Origine dell'attività controllata                              |

## Strumenti principali

La VM Kali può includere strumenti usati per test e verifica in laboratorio.

| Strumento       | Uso nel laboratorio                           |
| --------------- | --------------------------------------------- |
| `ping`          | Verifica raggiungibilità                      |
| `curl` / `wget` | Test HTTP e download controllati              |
| `nmap`          | Verifica controllata di porte e servizi       |
| `netcat`        | Test di connettività controllata              |
| `ssh`           | Connessioni amministrative o test controllati |

> Non versionare comandi offensivi completi, payload o script riutilizzabili fuori dal laboratorio.

## Relazione con Zeek

Zeek può osservare il traffico generato da AttackerVM se questo attraversa il punto di mirroring configurato su Open vSwitch.

Esempi di evidenze Zeek:

* connessioni tra AttackerVM e Client Linux;
* durata delle connessioni;
* porte sorgente e destinazione;
* traffico HTTP;
* traffico TCP persistente;
* log custom relativi alla reverse shell.

## Relazione con Wazuh

Wazuh osserva gli effetti degli scenari sugli host monitorati.

Nel caso del Client Linux, Wazuh può rilevare:

* eventi di autenticazione;
* modifiche al filesystem;
* eventi di sistema;
* possibili eventi FIM;
* alert generati a partire dai log custom Zeek.

## Verifiche utili

Verificare IP e routing:

```bash
ip addr
ip route
```

Verificare raggiungibilità di un target:

```bash
ping <TARGET_IP>
```

Verificare porte aperte in modo controllato:

```bash
nmap <TARGET_IP>
```

Verificare una connessione HTTP:

```bash
curl http://<TARGET_IP>
```

## Cosa versionare

È possibile versionare:

* documentazione della VM;
* note di configurazione non sensibili;
* elenco strumenti usati;
* comandi di verifica innocui;
* output ridotti e sanificati;
* evidenze sanificate;
* note sugli scenari eseguiti.

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

AttackerVM deve essere usata solo nel laboratorio isolato.

Questa directory documenta il ruolo della macchina attaccante senza distribuire materiale offensivo riutilizzabile fuori contesto.

## Best practice

* documentare solo attività realmente svolte;
* evitare comandi offensivi completi;
* non caricare payload o exploit;
* mantenere gli esempi sanificati;
* collegare gli scenari alle evidenze Zeek e Wazuh;
* aggiornare questo file se cambiano rete, IP, ruolo o scenari.
