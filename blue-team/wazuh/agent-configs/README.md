# Wazuh Agent Configurations

Questa directory contiene configurazioni sanificate degli agent Wazuh installati sulle VM del laboratorio.

## Obiettivo

L'obiettivo di questa directory è documentare le configurazioni degli agent Wazuh quando presentano modifiche rilevanti rispetto alla configurazione standard.

Gli agent raccolgono eventi locali dagli host monitorati e li inviano al Wazuh Manager.

## Stato attuale

Al momento viene versionata solo la configurazione dell'agent installato su ZeekVM, perché contiene modifiche specifiche per la raccolta dei log Zeek standard e custom.

Gli altri agent del laboratorio sono rimasti con configurazione standard o non presentano modifiche significative da documentare.

## File presenti

| File                    | Host   | Descrizione                                                               |
| ----------------------- | ------ | ------------------------------------------------------------------------- |
| `zeek-agent-ossec.conf` | ZeekVM | Configurazione agent Wazuh per la raccolta dei log Zeek standard e custom |

## Host monitorati

Gli agent Wazuh possono essere installati su:

| Host      | Stato documentazione | Note                               |
| --------- | -------------------- | ---------------------------------- |
| ZeekVM    | Documentato          | Configurazione custom per log Zeek |
| ClientVM  | Non versionato       | Configurazione standard/invariata  |
| WindowsVM | Non versionato       | Configurazione standard/invariata  |
| ServerDB  | Non versionato       | Configurazione standard/invariata  |
| VictimVM  | Non versionato       | Configurazione standard/invariata  |

## Zeek Agent

Il file:

```text
zeek-agent-ossec.conf
```

documenta la configurazione dell'agent Wazuh installato sulla VM Zeek.

Questa configurazione permette a Wazuh di raccogliere:

* log di sistema della VM Zeek;
* informazioni di inventory tramite Syscollector;
* eventi SCA;
* eventi File Integrity Monitoring;
* log Zeek standard da `/opt/zeek/logs/current/*.log`;
* log custom Zeek da `/var/log/zeek-custom/`.

## Log Zeek raccolti

L'agent Zeek raccoglie log standard da:

```text
/opt/zeek/logs/current/*.log
```

e log custom da:

```text
/var/log/zeek-custom/
```

I log custom principali sono:

| Log                          | Descrizione                                       |
| ---------------------------- | ------------------------------------------------- |
| `possible_malware.log`       | Possibile download o trasferimento sospetto       |
| `reverse_shell_live.log`     | Possibile reverse shell in corso                  |
| `reverse_shell_final.log`    | Evento finale o chiusura della reverse shell      |
| `reverse_shell_movement.log` | Traffico o movimento associato alla reverse shell |

## Flusso Zeek verso Wazuh

```text
Zeek logs
   |
   v
Wazuh Agent su ZeekVM
   |
   v
Wazuh Manager
   |
   v
Decoders
   |
   v
Rules
   |
   v
Alerts
```

## File da non versionare

Non caricare mai nella repository:

* `/var/ossec/etc/client.keys`;
* `/var/ossec/etc/authd.pass`;
* password;
* token;
* chiavi private;
* certificati privati;
* log completi;
* alert completi;
* file runtime;
* database interni Wazuh.

Nel file `zeek-agent-ossec.conf` può comparire il percorso:

```text
etc/authd.pass
```

Questo è solo un riferimento al file di enrollment e può rimanere documentato.

Il file reale `authd.pass` non deve essere caricato.

## Quando aggiungere altri agent

Aggiungere altri file agent solo se la configurazione differisce da quella standard.

Esempi futuri:

| File                              | Quando aggiungerlo                                                 |
| --------------------------------- | ------------------------------------------------------------------ |
| `client-linux-agent-ossec.conf`   | Se vengono aggiunti log custom o FIM specifici                     |
| `client-windows-agent-ossec.conf` | Se vengono configurati EventChannel o policy specifiche            |
| `server-db-agent-ossec.conf`      | Se vengono raccolti log PostgreSQL o FIM su configurazioni DB      |
| `victim-agent-ossec.conf`         | Se vengono monitorati file, directory o eventi legati agli scenari |

## Verifiche utili

Sulla VM Zeek:

```bash
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
```

Verificare che i log Zeek esistano:

```bash
ls -lh /opt/zeek/logs/current/
ls -lh /var/log/zeek-custom/
```

Verificare permessi dei log custom:

```bash
ls -lh /var/log/zeek-custom/
```

## Note operative

* Dopo modifiche a `ossec.conf`, riavviare l'agent interessato.
* Se cambiano i path dei log Zeek, aggiornare `zeek-agent-ossec.conf`.
* Se cambiano i log custom Zeek, aggiornare anche decoder e rules Wazuh.
* Se Wazuh non genera alert, verificare agent, manager, decoder, rules e permessi sui file.

## Best practice

* versionare solo configurazioni sanificate;
* evitare duplicati inutili se gli agent sono standard;
* documentare solo differenze significative;
* mantenere allineati agent config, decoder e rules;
* non caricare mai file di enrollment o chiavi agent.
