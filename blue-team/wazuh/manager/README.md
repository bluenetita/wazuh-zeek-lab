# Wazuh Manager

Questa directory documenta il ruolo del Wazuh Manager nel laboratorio.

## Obiettivo

Il Wazuh Manager è il componente centrale della piattaforma Wazuh.

Nel laboratorio riceve eventi dagli agent installati sugli host monitorati, applica decoder e regole, genera alert e supporta la correlazione tra eventi host-based e network-based.

## Ruolo nel laboratorio

Il Wazuh Manager è utilizzato per:

* ricevere eventi dagli agent Wazuh;
* normalizzare i log;
* applicare decoder custom;
* applicare regole custom;
* generare alert;
* raccogliere eventi di File Integrity Monitoring;
* raccogliere eventi di autenticazione;
* correlare eventi provenienti dagli host;
* ricevere eventi derivati dai log custom Zeek tramite l'agent installato su ZeekVM.

## Host monitorati

Gli agent Wazuh possono essere installati su:

| Host      | Ruolo                                  |
| --------- | -------------------------------------- |
| ZeekVM    | Raccolta log Zeek standard e custom    |
| ClientVM  | Endpoint Linux                         |
| WindowsVM | Endpoint Windows                       |
| ServerDB  | Server PostgreSQL                      |
| VictimVM  | Server vulnerabile usato negli scenari |

## Flusso degli eventi

Il flusso generale degli eventi è:

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

Zeek non invia direttamente eventi al Wazuh Manager.

Nel laboratorio, il flusso usato è:

```text
Zeek standard/custom logs
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

La configurazione dell'agent installato sulla VM Zeek si trova in:

```text
blue-team/wazuh/agent-configs/zeek-agent-ossec.conf
```

## Relazione con Zeek

Zeek fornisce visibilità a livello rete.

Wazuh Manager riceve gli eventi raccolti dall'agent installato su ZeekVM, tra cui:

* log Zeek standard;
* log Zeek custom;
* eventi relativi a reverse shell;
* eventi relativi a download sospetti;
* eventi relativi a connessioni persistenti;
* eventi correlabili con attività sugli host.

## Relazione con decoder e regole

I decoder trasformano i log grezzi in campi strutturati.

Le rules valutano questi campi e generano alert.

Directory correlate:

```text
blue-team/wazuh/decoders/
blue-team/wazuh/rules/
```

## File reali del manager

Sul Wazuh Manager, i file principali si trovano normalmente in:

```text
/var/ossec/etc/ossec.conf
/var/ossec/etc/decoders/
/var/ossec/etc/rules/
/var/ossec/logs/alerts/alerts.log
/var/ossec/logs/alerts/alerts.json
```

Nella repository devono essere versionati solo file sanificati, frammenti utili o documentazione.

## Cosa mettere in questa directory

Questa directory può contenere:

* note sul ruolo del manager;
* configurazioni manager sanificate;
* frammenti di configurazione utili;
* riferimenti a decoder e rules custom;
* procedure di verifica.

Per ora questa directory contiene solo documentazione.

Le configurazioni degli agent sono in:

```text
blue-team/wazuh/agent-configs/
```

## Cosa non mettere in questa directory

Non caricare:

* chiavi degli agent;
* password;
* token;
* certificati privati;
* log completi;
* alert completi non sanificati;
* database interni Wazuh;
* file runtime;
* configurazioni non controllate.

## Verifiche utili

Controllare stato del manager:

```bash
sudo systemctl status wazuh-manager
```

Riavviare il manager:

```bash
sudo systemctl restart wazuh-manager
```

Controllare log interni Wazuh:

```bash
sudo tail -f /var/ossec/logs/ossec.log
```

Controllare eventuali errori relativi a decoder e regole:

```bash
sudo grep -iE "error|decoder|rule" /var/ossec/logs/ossec.log
```

Controllare alert generati:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.log
```

oppure:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

## Note operative

* Dopo modifiche a decoder o regole, riavviare il Wazuh Manager.
* Dopo modifiche alla configurazione degli agent, riavviare l'agent interessato.
* Non caricare alert reali completi nella repository.
* Usare esempi sanificati in `blue-team/wazuh/log-samples/`.
* Documentare ogni regola custom indicando lo scenario collegato.

## Best practice

* separare configurazioni manager e configurazioni agent;
* mantenere decoder e rules in directory dedicate;
* usare esempi sanificati;
* testare ogni modifica con eventi controllati;
* documentare il flusso Zeek → Wazuh;
* evitare di versionare file sensibili o runtime.
