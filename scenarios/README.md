# Scenarios

Questa directory contiene la documentazione degli scenari simulati nel cyber range.

## Obiettivo

La sezione `scenarios/` documenta gli scenari effettivamente eseguiti nel laboratorio, collegando attività red team, traffico osservato da Zeek ed evidenze raccolte da Wazuh.

L'obiettivo è descrivere cosa è stato simulato, quali sistemi sono stati coinvolti e quali evidenze sono state raccolte, senza includere payload, exploit o materiale offensivo riutilizzabile.

## Scenari documentati

| Scenario             | Directory               | Stato      |
| -------------------- | ----------------------- | ---------- |
| Reverse Shell        | `reverse-shell/`        | Completato |
| Privilege Escalation | `privilege-escalation/` | Completato |

La repository documenta solo scenari realmente simulati e validati nel laboratorio.

## Target principale

Il target principale degli scenari documentati è:

| Host                    | Ruolo                                                |
| ----------------------- | ---------------------------------------------------- |
| Client Linux / ClientVM | Endpoint Linux interno usato come target controllato |

## Macchina attaccante

| Host                    | Ruolo                                            |
| ----------------------- | ------------------------------------------------ |
| AttackerVM / Kali Linux | Macchina usata per generare attività controllata |

## Componenti di osservabilità

| Componente   | Ruolo                                             |
| ------------ | ------------------------------------------------- |
| Zeek         | Osservabilità network-based                       |
| Wazuh        | Osservabilità host-based e alerting               |
| pfSense      | Firewall tra rete esterna simulata e rete interna |
| RouterOS     | Routing inter-VLAN e inoltro verso pfSense        |
| Open vSwitch | Mirroring del traffico verso Zeek                 |

## Flusso generale

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
Client Linux
   |
   v
Evidenze Zeek / Wazuh
```

## Reverse Shell

Lo scenario Reverse Shell documenta una comunicazione controllata tra Client Linux e AttackerVM.

Obiettivi principali:

* osservare una connessione persistente;
* generare log custom Zeek;
* inviare eventi Zeek a Wazuh;
* validare decoder e regole custom;
* verificare la correlazione tra eventi network-based e alert Wazuh.

Documentazione:

```text
scenarios/reverse-shell/
```

## Privilege Escalation

Lo scenario Privilege Escalation documenta attività locali sul Client Linux successive alla compromissione simulata.

Obiettivi principali:

* osservare attività host-based;
* valutare la visibilità di Wazuh;
* evidenziare i limiti della sola osservabilità di rete;
* distinguere eventi locali da eventi network-based.

Documentazione:

```text
scenarios/privilege-escalation/
```

## Relazione con Zeek

Zeek è particolarmente utile nello scenario Reverse Shell perché osserva il traffico tra Client Linux e AttackerVM.

Evidenze possibili:

* connessioni TCP;
* durata della connessione;
* IP sorgente e destinazione;
* porte coinvolte;
* byte trasferiti;
* log custom di reverse shell;
* eventi inoltrati a Wazuh.

## Relazione con Wazuh

Wazuh è utilizzato per:

* ricevere eventi dagli agent;
* leggere log custom Zeek;
* applicare decoder e rules custom;
* generare alert;
* osservare attività locali sul Client Linux;
* correlare eventi host-based e network-based.

## Directory correlate

| Directory                         | Descrizione                                  |
| --------------------------------- | -------------------------------------------- |
| `../red-team/`                    | Documentazione della componente attaccante   |
| `../red-team/attacker-kali/`      | Documentazione AttackerVM                    |
| `../infrastructure/client-linux/` | Documentazione del target Client Linux       |
| `../blue-team/zeek/`              | Configurazione Zeek e log custom             |
| `../blue-team/wazuh/`             | Configurazione Wazuh, decoder, rules e alert |
| `../proxmox/ovs/`                 | Mirroring OVS verso Zeek                     |
| `../network/routeros/`            | Routing inter-VLAN                           |
| `../network/pfsense/`             | Firewall e rete esterna simulata             |

## Cosa documentare per ogni scenario

Ogni scenario dovrebbe includere:

* obiettivo;
* VM coinvolte;
* percorso del traffico;
* componenti di osservabilità coinvolti;
* evidenze attese;
* evidenze ottenute;
* decoder e rules Wazuh coinvolti;
* limiti osservati;
* note di sicurezza;
* cosa non viene versionato.

## Cosa non includere

Non caricare nella repository:

* exploit funzionanti;
* payload;
* malware;
* reverse shell pronte all'uso;
* credenziali;
* token;
* chiavi private;
* dump;
* PCAP completi;
* log completi non sanificati;
* file generati durante compromissioni;
* comandi offensivi completi riutilizzabili fuori dal laboratorio.

## Evidenze sanificate

È possibile includere solo evidenze ridotte e sanificate, ad esempio:

* esempi di log Zeek;
* esempi di alert Wazuh;
* output sintetici;
* screenshot non sensibili;
* descrizioni dei risultati.

Le evidenze complete devono rimanere fuori dalla repository.

## Note operative

Questa directory descrive scenari svolti in ambiente isolato.

La documentazione deve essere sufficiente per comprendere il flusso dello scenario e le evidenze raccolte, ma non deve trasformarsi in una guida offensiva riutilizzabile fuori dal contesto del laboratorio.

## Best practice

* documentare solo scenari effettivamente simulati;
* mantenere separati scenario, configurazioni ed evidenze;
* collegare ogni scenario a Zeek e Wazuh;
* non caricare payload o exploit;
* usare placeholder per IP, hash o dati sensibili;
* indicare chiaramente limiti e osservazioni.
