# Wazuh Log Samples

Questa directory contiene esempi sanificati di log e alert generati da Wazuh.

## Obiettivo

Gli esempi servono a documentare il tipo di evidenze prodotte da Wazuh durante gli scenari del laboratorio.

Questi file aiutano a capire:

* quali alert vengono generati;
* quali campi sono utili durante l'analisi;
* come Wazuh interpreta i log Zeek custom;
* come appaiono gli alert di correlazione;
* quali eventi host-based possono essere confrontati con Zeek.

## Regola principale

In questa directory devono essere caricati solo esempi ridotti e sanificati.

Non caricare log completi reali.

Non caricare file contenenti dati sensibili.

## File previsti

| File                                    | Descrizione                                         |
| --------------------------------------- | --------------------------------------------------- |
| `zeek-custom-alert-sample.json`         | Esempio di alert Wazuh generato da log custom Zeek  |
| `reverse-shell-correlation-sample.json` | Esempio di alert correlato relativo a reverse shell |
| `fim-alert-sample.json`                 | Esempio di alert File Integrity Monitoring          |

## Fonti dei log

Gli alert possono provenire da:

| Fonte             | Percorso tipico                      |
| ----------------- | ------------------------------------ |
| Alert JSON        | `/var/ossec/logs/alerts/alerts.json` |
| Alert plain text  | `/var/ossec/logs/alerts/alerts.log`  |
| Log interni Wazuh | `/var/ossec/logs/ossec.log`          |
| Agent config      | `/var/ossec/etc/ossec.conf`          |

## Placeholder consigliati

Sostituire sempre valori reali con placeholder.

| Valore reale        | Placeholder         |
| ------------------- | ------------------- |
| IP macchina Kali    | `ATTACKER_IP`       |
| IP macchina vittima | `VICTIM_IP`         |
| IP Zeek             | `ZEEK_IP`           |
| IP Wazuh Manager    | `WAZUH_MANAGER_IP`  |
| Hostname reale      | `HOSTNAME_REDACTED` |
| Nome agent reale    | `AGENT_NAME`        |
| ID agent reale      | `AGENT_ID`          |
| Timestamp reale     | `TIMESTAMP`         |
| UID Zeek reale      | `UID`               |
| Hash reale          | `HASH_REDACTED`     |
| Path sensibile      | `PATH_REDACTED`     |

## Cosa non caricare

Non caricare:

* `alerts.log` completo;
* `alerts.json` completo;
* `ossec.log` completo;
* `client.keys`;
* `authd.pass`;
* credenziali;
* token;
* chiavi private;
* certificati;
* dati personali;
* IP pubblici sensibili;
* payload;
* malware;
* log troppo lunghi.

## Come creare un sample sicuro

Partire da un alert reale e copiare solo un singolo evento rilevante.

Esempio:

```bash
sudo tail -n 20 /var/ossec/logs/alerts/alerts.json
```

Copiare un solo oggetto JSON e sostituire i valori sensibili con placeholder.

Esempio di sostituzioni:

```text
10.3.30.10 -> VICTIM_IP
10.2.0.10 -> ATTACKER_IP
001 -> AGENT_ID
zeekvm -> ZEEK_AGENT
1740000000.12345 -> TIMESTAMP
CAbCdEf123456 -> UID
```

## Relazione con Zeek

Wazuh può generare alert a partire dai log custom Zeek raccolti dall'agent installato su ZeekVM.

Flusso:

```text
Zeek custom logs
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

## Relazione con gli scenari

| Scenario                  | Sample utile                            |
| ------------------------- | --------------------------------------- |
| Reverse Shell             | `reverse-shell-correlation-sample.json` |
| Malware Download          | `zeek-custom-alert-sample.json`         |
| Privilege Escalation      | `fim-alert-sample.json`                 |
| File Integrity Monitoring | `fim-alert-sample.json`                 |

## Controlli prima del commit

Prima di fare commit:

```bash
grep -RniE "password|passwd|secret|key|private|token|cert|authd|client.keys" blue-team/wazuh/log-samples/
```

Controllare manualmente anche il diff:

```bash
git diff blue-team/wazuh/log-samples/
```

## Best practice

* mantenere i sample piccoli;
* usare placeholder coerenti;
* includere solo eventi utili;
* documentare a quale scenario si riferisce il sample;
* non caricare log grezzi completi;
* non caricare file runtime Wazuh;
* aggiornare i sample quando cambiano regole o decoder custom.

## Note finali

Questa directory serve a documentare esempi di evidenze, non ad archiviare tutti gli alert del laboratorio.

I log reali completi devono rimanere fuori dalla repository.
