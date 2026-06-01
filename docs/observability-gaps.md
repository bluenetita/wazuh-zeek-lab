# Observability Gaps

Questo documento descrive i limiti di visibilità osservati nel cyber range e chiarisce quali eventi possono essere rilevati da Zeek, Wazuh, pfSense, RouterOS e dagli altri componenti del laboratorio.

## Obiettivo

L'obiettivo di questo documento è evidenziare cosa viene osservato correttamente dai sistemi di monitoraggio e cosa invece può rimanere parzialmente o totalmente fuori visibilità.

Nel laboratorio sono presenti due principali forme di osservabilità:

| Tipo          | Strumento principale | Descrizione                                 |
| ------------- | -------------------- | ------------------------------------------- |
| Network-based | Zeek                 | Osservazione del traffico di rete           |
| Host-based    | Wazuh                | Osservazione degli eventi locali sugli host |

La combinazione di Zeek e Wazuh permette una visibilità più completa, ma non elimina tutti i gap.

## Componenti coinvolti

| Componente   | Visibilità principale                                 |
| ------------ | ----------------------------------------------------- |
| Zeek         | Traffico di rete mirrorato                            |
| Wazuh        | Eventi host-based e alert                             |
| pfSense      | Traffico permesso/bloccato tra rete esterna e interna |
| RouterOS     | Routing inter-VLAN e regole firewall                  |
| Open vSwitch | Duplicazione traffico verso Zeek                      |
| Proxmox      | Virtualizzazione e collegamenti tra VM                |

## Visibilità di Zeek

Zeek osserva il traffico di rete ricevuto tramite mirror Open vSwitch.

Nel laboratorio Zeek è utile per osservare:

* connessioni TCP;
* traffico tra Client Linux e AttackerVM;
* traffico tra VLAN;
* query DNS;
* traffico HTTP;
* metadati TLS;
* connessioni persistenti;
* eventi custom relativi alla reverse shell;
* possibili trasferimenti o download sospetti.

## Limiti di Zeek

Zeek ha visibilità limitata o assente su eventi che non generano traffico di rete.

| Attività                            | Visibilità Zeek                 |
| ----------------------------------- | ------------------------------- |
| Comandi eseguiti localmente         | Non visibile                    |
| Privilege escalation locale         | Non direttamente visibile       |
| Modifiche al filesystem             | Non visibile                    |
| Creazione/modifica utenti locali    | Non visibile                    |
| Modifica permessi locali            | Non visibile                    |
| Processi locali                     | Non visibile                    |
| Traffico cifrato                    | Visibilità limitata ai metadati |
| Traffico non incluso nel mirror OVS | Non visibile                    |

## Visibilità di Wazuh

Wazuh osserva eventi host-based tramite agent installati sugli host monitorati.

Nel laboratorio Wazuh è utile per osservare:

* log di sistema;
* autenticazioni;
* eventi dell'agent;
* eventi File Integrity Monitoring;
* modifiche a file e directory monitorate;
* inventory di sistema;
* alert generati da regole standard;
* alert generati da decoder e rules custom;
* log custom Zeek raccolti dall'agent su ZeekVM.

## Limiti di Wazuh

Wazuh dipende dalla presenza e dalla corretta configurazione degli agent.

| Condizione                      | Impatto                          |
| ------------------------------- | -------------------------------- |
| Agent non installato            | Nessuna visibilità host-based    |
| Agent non connesso al manager   | Eventi non ricevuti              |
| File non monitorato             | Modifiche non rilevate           |
| Regole non configurate          | Alert non generati               |
| Log non raccolto da `localfile` | Evento non analizzato            |
| Evento non coperto da decoder   | Campi non estratti correttamente |
| Evento non coperto da rule      | Nessun alert specifico           |

## Reverse Shell

Lo scenario Reverse Shell è osservabile principalmente tramite Zeek e Wazuh.

### Visibilità attesa

| Componente   | Visibilità                                           |
| ------------ | ---------------------------------------------------- |
| Zeek         | Connessioni TCP, traffico persistente, log custom    |
| Wazuh        | Alert generati dai log Zeek custom                   |
| pfSense      | Traffico permesso o bloccato                         |
| RouterOS     | Inoltro tra rete esterna e VLAN Client               |
| Client Linux | Eventuali log locali                                 |
| AttackerVM   | Origine o destinazione della connessione controllata |

### Gap osservabili

Zeek può osservare la comunicazione di rete, ma non può sapere da solo quale comando locale venga eseguito sul Client Linux.

Wazuh può generare alert a partire dai log custom Zeek, ma la qualità dell'alert dipende da:

* formato del log custom;
* decoder configurati;
* rules custom;
* corretto inoltro tramite Wazuh Agent;
* presenza dei campi necessari alla correlazione.

## Privilege Escalation

Lo scenario Privilege Escalation è osservabile principalmente tramite Wazuh.

### Visibilità attesa

| Componente   | Visibilità                              |
| ------------ | --------------------------------------- |
| Wazuh        | Eventi host-based, FIM, log locali      |
| Zeek         | Eventuale traffico di rete correlato    |
| pfSense      | Solo traffico attraversato dal firewall |
| RouterOS     | Solo traffico instradato                |
| OVS          | Solo traffico duplicato                 |
| Client Linux | Log locali e modifiche di sistema       |

### Gap osservabili

La Privilege Escalation avviene principalmente sul sistema target.

Per questo motivo:

* Zeek ha visibilità limitata;
* pfSense non vede attività locali;
* RouterOS non vede eventi host-based;
* OVS non vede modifiche interne al sistema;
* Wazuh è il componente più importante per questo scenario.

## Gap tra network-based e host-based detection

| Evento                      | Zeek                       | Wazuh                          |
| --------------------------- | -------------------------- | ------------------------------ |
| Connessione TCP             | Alta visibilità            | Dipende dai log host           |
| Traffico persistente        | Alta visibilità            | Dipende da eventi locali       |
| Download via rete           | Buona visibilità           | Dipende da log/FIM             |
| Modifica file locale        | Nessuna visibilità         | Buona visibilità se monitorata |
| Privilege escalation locale | Nessuna visibilità diretta | Possibile visibilità           |
| Login fallito               | Limitata                   | Buona visibilità               |
| Processo sospetto           | Nessuna visibilità         | Possibile visibilità           |
| Traffico cifrato            | Metadati                   | Eventi host, se disponibili    |

## Gap del mirroring OVS

Zeek vede solo il traffico che riceve tramite mirror.

Possibili cause di mancata visibilità:

* traffico non attraversa `vmbr2`;
* VLAN non inclusa nel mirror;
* VLAN 999 non raggiunge ZeekVM;
* interfaccia Zeek non configurata correttamente;
* interfaccia non in modalità promiscua;
* mirror OVS non attivo dopo reboot;
* script `ovs-mirror.sh` non eseguito;
* servizio `ovs-mirror.service` non abilitato.

## Gap dovuti alla cifratura

Quando il traffico è cifrato, Zeek può osservare principalmente metadati.

Esempi:

* IP sorgente;
* IP destinazione;
* porte;
* durata;
* byte trasferiti;
* informazioni TLS disponibili;
* SNI, se presente.

Zeek non può leggere il contenuto applicativo cifrato senza decryption.

## Gap di pfSense

pfSense fornisce visibilità sul traffico permesso o bloccato tra rete esterna simulata e rete interna.

Limiti:

* non interpreta in profondità la semantica dello scenario;
* non vede attività locali sugli host;
* non vede traffico che non attraversa il firewall;
* dipende dalle regole di logging abilitate.

## Gap di RouterOS

RouterOS gestisce routing e firewall inter-VLAN.

Limiti:

* non fornisce detection applicativa avanzata;
* non vede comandi locali sugli host;
* non interpreta log Zeek o Wazuh;
* mostra principalmente traffico, regole e routing.

## Gap di evidenza

Le evidenze nella repository sono sanificate.

Questo significa che alcuni dettagli reali vengono sostituiti con placeholder, ad esempio:

| Valore reale    | Placeholder     |
| --------------- | --------------- |
| IP AttackerVM   | `ATTACKER_IP`   |
| IP Client Linux | `CLIENT_IP`     |
| Timestamp reale | `TIMESTAMP`     |
| UID Zeek        | `UID`           |
| Hash reale      | `HASH_REDACTED` |
| Username reale  | `USER_REDACTED` |
| Path sensibile  | `PATH_REDACTED` |

La sanificazione migliora la sicurezza della repository, ma riduce alcuni dettagli tecnici dell'evidenza originale.

## Strategie di mitigazione

Per ridurre i gap di osservabilità:

* verificare periodicamente il mirror OVS;
* controllare che Zeek riceva traffico con `tcpdump`;
* verificare che i log custom Zeek vengano generati;
* controllare che l'agent Wazuh su ZeekVM raccolga i log custom;
* verificare decoder e rules Wazuh;
* installare e configurare agent Wazuh sugli host rilevanti;
* abilitare FIM su file e directory importanti;
* mantenere documentati i path dei log;
* usare evidenze sanificate ma rappresentative.

## Verifiche utili

### Proxmox / OVS

```bash
ovs-vsctl show
ovs-vsctl list mirror
systemctl status ovs-mirror.service
tail -f /var/log/ovs-mirror.log
```

### ZeekVM

```bash
sudo tcpdump -i ens19 -n
sudo tcpdump -i ens19.999 -n
sudo /opt/zeek/bin/zeekctl status
ls -lh /var/log/zeek-custom/
```

### Wazuh Manager

```bash
sudo tail -f /var/ossec/logs/ossec.log
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

### Client Linux

```bash
ip addr
ip route
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
```

## Relazione con gli scenari

| Scenario             | Visibilità principale | Gap principale                                         |
| -------------------- | --------------------- | ------------------------------------------------------ |
| Reverse Shell        | Zeek e Wazuh          | Zeek vede la rete, ma non i comandi locali             |
| Privilege Escalation | Wazuh                 | Zeek ha visibilità limitata perché l'attività è locale |

## Directory correlate

| Directory                         | Descrizione                     |
| --------------------------------- | ------------------------------- |
| `../blue-team/zeek/`              | Configurazione Zeek             |
| `../blue-team/wazuh/`             | Configurazione Wazuh            |
| `../proxmox/ovs/`                 | Mirror OVS verso Zeek           |
| `../scenarios/`                   | Scenari simulati                |
| `../evidence/`                    | Evidenze sanificate             |
| `../infrastructure/client-linux/` | Target principale degli scenari |

## Conclusioni

La principale lezione osservata è che nessun singolo strumento fornisce visibilità completa.

Zeek è efficace per analizzare traffico di rete e connessioni sospette.

Wazuh è più adatto a osservare eventi locali, modifiche al filesystem e attività host-based.

La combinazione di Zeek e Wazuh migliora la capacità di rilevare e correlare eventi, ma richiede configurazione corretta di mirror, agent, decoder, rules e raccolta log.
