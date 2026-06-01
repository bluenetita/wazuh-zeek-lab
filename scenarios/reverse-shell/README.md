# Reverse Shell Scenario

Questa directory contiene la documentazione dello scenario Reverse Shell simulato nel cyber range.

## Obiettivo

Lo scenario ha l'obiettivo di documentare una comunicazione controllata tra Client Linux e AttackerVM, osservando quali evidenze vengono generate a livello network-based e come queste vengono raccolte e correlate da Zeek e Wazuh.

L'obiettivo principale non è documentare il payload o la tecnica offensiva in dettaglio, ma descrivere il flusso, i sistemi coinvolti e le evidenze di detection ottenute.

## Stato

| Campo                 | Valore                  |
| --------------------- | ----------------------- |
| Scenario              | Reverse Shell           |
| Stato                 | Completato              |
| Target                | Client Linux / ClientVM |
| Macchina attaccante   | AttackerVM / Kali Linux |
| Ambiente              | Cyber range isolato     |
| Visibilità principale | Zeek                    |
| Correlazione alert    | Wazuh                   |

## VM coinvolte

| VM                      | Ruolo                                                    |
| ----------------------- | -------------------------------------------------------- |
| AttackerVM / Kali Linux | Macchina esterna usata per generare attività controllata |
| Client Linux / ClientVM | Target dello scenario                                    |
| ZeekVM                  | Analisi traffico di rete e generazione log custom        |
| WazuhVM                 | Raccolta eventi, decoder, rules e alert                  |
| RouterOS                | Routing tra VLAN interne e transito verso pfSense        |
| pfSense                 | Firewall tra rete esterna simulata e rete interna        |
| Proxmox / OVS           | Mirroring del traffico verso Zeek                        |

## Target

Il target dello scenario è:

```text
Client Linux / ClientVM
```

Il Client Linux rappresenta un endpoint interno della rete aziendale simulata.

## Percorso del traffico

Il traffico tra AttackerVM e Client Linux attraversa pfSense, RouterOS e i bridge virtuali configurati su Proxmox.

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

## Mirroring verso Zeek

Il traffico interno viene duplicato da Open vSwitch verso Zeek tramite mirror configurato su Proxmox.

```text
VLAN Client
   |
   v
vmbr2 / Open vSwitch
   |
   +--> traffico originale
   |
   +--> copia del traffico su VLAN 999
           |
           v
        ZeekVM
```

## Descrizione dello scenario

Lo scenario simula una connessione controllata tra Client Linux e AttackerVM.

Durante lo scenario vengono osservati:

* connessione TCP tra Client Linux e AttackerVM;
* traffico persistente;
* eventuale download o trasferimento collegato allo scenario;
* log custom generati da Zeek;
* alert Wazuh generati tramite decoder e rules custom;
* eventuale correlazione tra più eventi.

## Flusso logico

```text
AttackerVM / Kali
   |
   v
Connessione controllata con Client Linux
   |
   v
Traffico osservato da Zeek
   |
   v
Log custom Zeek
   |
   v
Wazuh Agent su ZeekVM
   |
   v
Wazuh Manager
   |
   v
Decoder / Rules / Alert
```

## Evidenze Zeek

Zeek è il componente principale per l'osservabilità network-based dello scenario.

Evidenze attese:

| Log Zeek     | Evidenza                                       |
| ------------ | ---------------------------------------------- |
| `conn.log`   | Connessione TCP tra Client Linux e AttackerVM  |
| `http.log`   | Eventuale traffico HTTP o download controllato |
| `weird.log`  | Eventuali anomalie di protocollo               |
| `notice.log` | Eventuali notice generate da Zeek              |
| Log custom   | Eventi specifici dello scenario reverse shell  |

## Log custom Zeek

I log custom collegati allo scenario sono salvati in:

```text
/var/log/zeek-custom/
```

Log principali:

| Log                          | Descrizione                                                         |
| ---------------------------- | ------------------------------------------------------------------- |
| `possible_malware.log`       | Possibile download o trasferimento sospetto collegato allo scenario |
| `reverse_shell_live.log`     | Possibile reverse shell in corso                                    |
| `reverse_shell_movement.log` | Traffico associato alla connessione                                 |
| `reverse_shell_final.log`    | Chiusura o classificazione finale della connessione                 |

## Evidenze Wazuh

Wazuh riceve i log Zeek tramite l'agent installato sulla VM Zeek.

La configurazione dell'agent è documentata in:

```text
blue-team/wazuh/agent-configs/zeek-agent-ossec.conf
```

Evidenze attese:

| Fonte                 | Evidenza                               |
| --------------------- | -------------------------------------- |
| Wazuh Agent su ZeekVM | Raccolta log custom Zeek               |
| Wazuh Manager         | Applicazione decoder e rules           |
| Wazuh Alerts          | Alert custom relativi allo scenario    |
| Correlation rules     | Ricostruzione della sequenza di eventi |

## Decoder coinvolti

I decoder coinvolti sono documentati in:

```text
blue-team/wazuh/decoders/
```

File principali:

| File                      | Scopo                         |
| ------------------------- | ----------------------------- |
| `zeek_decoders.xml`       | Decoder per log Zeek standard |
| `zeek_decoder_custom.xml` | Decoder per log custom Zeek   |

## Rules coinvolte

Le rules coinvolte sono documentate in:

```text
blue-team/wazuh/rules/
```

File principali:

| File                        | Scopo                                    |
| --------------------------- | ---------------------------------------- |
| `001_zeek_rules.xml`        | Regole per log Zeek standard             |
| `002_zeek_rules_custom.xml` | Regole per log custom Zeek               |
| `003_zeek_correlations.xml` | Regole di correlazione per reverse shell |

## Regole custom principali

|  Rule ID | Log sorgente                 | Descrizione                                  |
| -------: | ---------------------------- | -------------------------------------------- |
| `100909` | `possible_malware.log`       | Possibile download o trasferimento sospetto  |
| `100910` | `reverse_shell_live.log`     | Possibile reverse shell live                 |
| `100912` | `reverse_shell_movement.log` | Traffico compatibile con reverse shell       |
| `100911` | `reverse_shell_final.log`    | Evento finale o chiusura della reverse shell |

## Correlazioni Wazuh

Le regole di correlazione permettono di collegare più eventi dello stesso scenario.

Esempio di catena logica:

```text
possible_malware
   |
   v
reverse_shell_live
   |
   v
reverse_shell_movement
   |
   v
reverse_shell_final
```

La correlazione permette di distinguere un singolo evento isolato da una sequenza più significativa.

## Evidenze ottenute

Questa sezione può essere compilata con risultati sanificati.

Esempio:

```text
- Zeek ha osservato una connessione persistente tra Client Linux e AttackerVM.
- Gli script custom Zeek hanno generato log dedicati allo scenario.
- Wazuh ha raccolto i log custom tramite l'agent installato su ZeekVM.
- Le regole custom Wazuh hanno generato alert relativi alla reverse shell.
- Le regole di correlazione hanno permesso di collegare più eventi della stessa sequenza.
```

## Verifiche utili

### Su Proxmox

Verificare mirror OVS:

```bash
ovs-vsctl list mirror
```

Verificare servizio mirror:

```bash
systemctl status ovs-mirror.service
```

### Su ZeekVM

Verificare traffico sull'interfaccia di monitoring:

```bash
sudo tcpdump -i ens19 -n
sudo tcpdump -i ens19.999 -n
```

Verificare stato Zeek:

```bash
sudo /opt/zeek/bin/zeekctl status
```

Verificare log custom:

```bash
ls -lh /var/log/zeek-custom/
```

### Su Wazuh Manager

Verificare log interni:

```bash
sudo tail -f /var/ossec/logs/ossec.log
```

Verificare alert:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.log
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

## Limiti osservati

| Componente | Limite                                                                            |
| ---------- | --------------------------------------------------------------------------------- |
| Zeek       | Osserva il traffico, ma non vede direttamente comandi locali eseguiti sul client  |
| Wazuh      | Dipende dalla corretta raccolta dei log e dalle rules configurate                 |
| pfSense    | Osserva traffico permesso/bloccato, ma non interpreta la semantica dello scenario |
| RouterOS   | Gestisce routing, ma non fornisce detection applicativa                           |
| OVS mirror | Osserva solo traffico incluso nel mirror                                          |

## Collegamenti con altre directory

| Directory                            | Descrizione                           |
| ------------------------------------ | ------------------------------------- |
| `../../red-team/attacker-kali/`      | Documentazione AttackerVM             |
| `../../infrastructure/client-linux/` | Documentazione Client Linux           |
| `../../blue-team/zeek/`              | Configurazione Zeek                   |
| `../../blue-team/wazuh/`             | Configurazione Wazuh, decoder e rules |
| `../../proxmox/ovs/`                 | Configurazione mirror OVS             |
| `../../network/routeros/`            | Routing inter-VLAN                    |
| `../../network/pfsense/`             | Firewall e rete esterna simulata      |

## Cosa includere nella repository

È possibile includere:

* descrizione dello scenario;
* evidenze sanificate;
* esempi ridotti di log Zeek;
* esempi ridotti di alert Wazuh;
* riferimenti a decoder e rules;
* note sui risultati ottenuti;
* osservazioni sui limiti di detection.

## Cosa non includere

Non caricare:

* payload;
* exploit;
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

Questo scenario deve essere documentato come attività svolta in ambiente controllato e isolato.

La documentazione deve concentrarsi sulle evidenze di detection, sulla correlazione Zeek/Wazuh e sui limiti osservati, evitando di includere materiale offensivo riutilizzabile fuori dal laboratorio.

## Conclusioni

Lo scenario Reverse Shell mostra il valore della combinazione tra Zeek e Wazuh.

Zeek fornisce visibilità sul traffico di rete e produce log custom relativi alla connessione.

Wazuh raccoglie questi log, applica decoder e rules custom, e genera alert utili per la detection e la correlazione dello scenario.
