# Wazuh

Questa directory contiene la documentazione e le configurazioni sanificate relative a Wazuh.

Wazuh è utilizzato nel laboratorio come sistema di Host-Based Intrusion Detection e Security Monitoring.

## Ruolo nel laboratorio

Wazuh fornisce visibilità a livello host.

Nel progetto viene utilizzato per:

* raccogliere eventi dagli host monitorati;
* analizzare log di sistema;
* monitorare modifiche al filesystem;
* raccogliere eventi di autenticazione;
* generare alert;
* applicare decoder custom;
* applicare regole custom;
* correlare eventi host-based con evidenze di rete prodotte da Zeek.

## Componenti principali

| Componente       | Ruolo                                                             |
| ---------------- | ----------------------------------------------------------------- |
| Wazuh Manager    | Riceve eventi dagli agent, applica decoder e regole, genera alert |
| Wazuh Agent      | Raccoglie eventi locali dagli host monitorati                     |
| Decoder          | Estrae campi strutturati dai log                                  |
| Rules            | Generano alert in base agli eventi ricevuti                       |
| Zeek integration | Permette di analizzare log Zeek standard e custom tramite Wazuh   |

## Host monitorati

Gli agent Wazuh possono essere installati su:

| Host      | Ruolo                                  |
| --------- | -------------------------------------- |
| ZeekVM    | Raccolta log Zeek standard e custom    |
| ClientVM  | Endpoint Linux interno                 |
| WindowsVM | Endpoint Windows interno               |
| ServerDB  | Server PostgreSQL                      |
| VictimVM  | Server vulnerabile usato negli scenari |

## Flusso degli eventi

Il flusso generale degli eventi Wazuh è:

```text
Host monitorato
   |
   v
Wazuh Agent
   |
   v
Wazuh Manager
   |
   v
Decoder
   |
   v
Rules
   |
   v
Alerts
```

## Flusso Zeek verso Wazuh

Nel laboratorio, Zeek produce log standard e log custom.

L'agent Wazuh installato su ZeekVM raccoglie questi log e li invia al Wazuh Manager.

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
Decoder custom
   |
   v
Rules custom
   |
   v
Alert Wazuh
```

I log Zeek raccolti includono:

* log standard da `/opt/zeek/logs/current/*.log`;
* log custom da `/var/log/zeek-custom/`.

## Log custom Zeek

I log custom Zeek usati nel progetto includono:

| Log                          | Scopo                                                 |
| ---------------------------- | ----------------------------------------------------- |
| `possible_malware.log`       | Possibile download o trasferimento sospetto           |
| `reverse_shell_live.log`     | Connessioni persistenti compatibili con reverse shell |
| `reverse_shell_final.log`    | Evento finale o classificazione dello scenario        |
| `reverse_shell_movement.log` | Pattern collegati ad attività sospetta                |

## Directory

| Directory        | Descrizione                                     |
| ---------------- | ----------------------------------------------- |
| `manager/`       | Documentazione del ruolo del Wazuh Manager      |
| `agent-configs/` | Configurazioni sanificate degli agent Wazuh     |
| `decoders/`      | Decoder XML custom                              |
| `rules/`         | Regole XML custom                               |
| `integrations/`  | Documentazione delle integrazioni, inclusa Zeek |
| `log-samples/`   | Esempi sanificati di log e alert                |

## File importanti

Percorsi tipici sul Wazuh Manager:

```text
/var/ossec/etc/ossec.conf
/var/ossec/etc/decoders/
/var/ossec/etc/rules/
/var/ossec/logs/alerts/alerts.log
/var/ossec/logs/alerts/alerts.json
```

Percorsi tipici sugli agent:

```text
/var/ossec/etc/ossec.conf
/var/ossec/etc/client.keys
/var/ossec/logs/ossec.log
```

Nella repository devono essere versionati solo file sanificati o documentazione.

## Configurazioni agent

Le configurazioni degli agent sono documentate in:

```text
blue-team/wazuh/agent-configs/
```

Il file più importante è:

```text
blue-team/wazuh/agent-configs/zeek-agent-ossec.conf
```

Questo file documenta la configurazione dell'agent installato sulla VM Zeek e include la raccolta dei log Zeek standard e custom.

## Decoder custom

I decoder custom sono documentati in:

```text
blue-team/wazuh/decoders/
```

Servono per interpretare log custom Zeek o altri log specifici del laboratorio.

## Rules custom

Le regole custom sono documentate in:

```text
blue-team/wazuh/rules/
```

Servono per generare alert a partire dagli eventi normalizzati dai decoder.

## Relazione con Zeek

Zeek osserva il traffico di rete.

Wazuh osserva eventi host-based.

La loro integrazione permette di correlare:

* connessioni sospette;
* reverse shell;
* download di payload;
* modifiche locali al filesystem;
* tentativi di autenticazione;
* traffico persistente verso host esterni;
* eventi generati da script custom Zeek.

## Relazione con gli scenari

| Scenario             | Ruolo di Wazuh                                              |
| -------------------- | ----------------------------------------------------------- |
| Reverse Shell        | Riceve log custom Zeek e possibili eventi host-based        |
| Privilege Escalation | Osserva modifiche locali, FIM, permessi e cronjob           |

## Verifiche utili

Controllare stato del manager:

```bash
sudo systemctl status wazuh-manager
```

Controllare stato di un agent Linux:

```bash
sudo systemctl status wazuh-agent
```

Controllare log del manager o dell'agent:

```bash
sudo tail -f /var/ossec/logs/ossec.log
```

Controllare alert:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.log
```

oppure:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

## Cosa versionare

È possibile versionare:

* configurazioni agent sanificate;
* decoder XML custom;
* regole XML custom;
* esempi di log sanificati;
* esempi di alert sanificati;
* documentazione dei flussi di integrazione;
* note operative e troubleshooting.

## Cosa non versionare

Non caricare:

* `client.keys`;
* `authd.pass`;
* password;
* token;
* chiavi private;
* certificati privati;
* log completi;
* alert completi;
* database interni Wazuh;
* file runtime;
* dati personali;
* configurazioni non controllate.

## Sanificazione

Prima di fare commit, controllare che non siano presenti dati sensibili:

```bash
grep -RniE "password|passwd|secret|key|private|token|cert|authd|client.keys" blue-team/wazuh/
```

Controllare anche il diff:

```bash
git diff blue-team/wazuh/
```

## Best practice

* separare manager, agent, decoder e rules;
* usare configurazioni sanificate;
* documentare ogni regola custom;
* collegare ogni regola allo scenario corrispondente;
* testare ogni modifica con eventi controllati;
* non caricare log grezzi completi;
* mantenere coerenti Wazuh, Zeek e gli scenari.
