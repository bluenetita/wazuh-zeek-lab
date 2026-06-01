# Wazuh Evidence - Reverse Shell

Questa directory contiene evidenze sanificate prodotte da Wazuh durante lo scenario Reverse Shell.

## Obiettivo

L'obiettivo è documentare gli alert e le correlazioni Wazuh generati a partire dai log custom Zeek relativi allo scenario Reverse Shell.

Le evidenze devono mostrare cosa è stato effettivamente osservato e correlato, senza includere log completi, payload, exploit, credenziali o dati sensibili.

## Scenario di riferimento

| Campo               | Valore                  |
| ------------------- | ----------------------- |
| Scenario            | Reverse Shell           |
| Stato               | Completato              |
| Target              | Client Linux / ClientVM |
| Macchina attaccante | AttackerVM / Kali Linux |
| Fonte principale    | Wazuh                   |
| Origine eventi      | Log custom Zeek         |
| Tipo evidenza       | Alert e correlazioni    |

## Ruolo di Wazuh

Wazuh riceve i log custom Zeek tramite l'agent installato sulla VM Zeek.

Il flusso è:

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
Alert / Correlazioni
```

## Log custom Zeek coinvolti

Gli alert Wazuh possono derivare dai seguenti log custom:

| Log                          | Descrizione                                         |
| ---------------------------- | --------------------------------------------------- |
| `possible_malware.log`       | Possibile download o trasferimento sospetto         |
| `reverse_shell_live.log`     | Possibile reverse shell in corso                    |
| `reverse_shell_movement.log` | Traffico associato alla connessione                 |
| `reverse_shell_final.log`    | Chiusura o classificazione finale della connessione |

## Rules Wazuh coinvolte

Le principali regole custom collegate allo scenario sono:

|  Rule ID | Descrizione                                           |
| -------: | ----------------------------------------------------- |
| `100909` | Possibile download o trasferimento sospetto           |
| `100910` | Possibile reverse shell live                          |
| `100912` | Traffico compatibile con reverse shell                |
| `100911` | Evento finale o chiusura reverse shell                |
| `110900` | Download sospetto seguito da avvio reverse shell      |
| `110901` | Download sospetto seguito da traffico reverse shell   |
| `110902` | Ciclo completo reverse shell dopo download sospetto   |
| `110906` | Reverse shell start seguito da traffico               |
| `110907` | Ciclo completo reverse shell senza evento di download |

## Tipi di evidenze ammesse

È possibile includere esempi piccoli e sanificati come:

```text
wazuh-alert-possible-malware-sample.json
wazuh-alert-reverse-shell-live-sample.json
wazuh-alert-reverse-shell-movement-sample.json
wazuh-alert-reverse-shell-final-sample.json
wazuh-correlation-reverse-shell-sample.json
notes.md
```

## Tipi di evidenze non ammesse

Non caricare:

* `alerts.json` completo;
* `alerts.log` completo;
* `ossec.log` completo;
* log grezzi completi;
* payload;
* exploit;
* malware;
* reverse shell pronte all'uso;
* comandi offensivi completi;
* credenziali;
* token;
* chiavi private;
* dump;
* PCAP completi;
* file generati durante compromissioni.

## Placeholder consigliati

Prima di inserire una evidenza, sostituire i dati reali con placeholder.

| Valore reale    | Placeholder         |
| --------------- | ------------------- |
| IP AttackerVM   | `ATTACKER_IP`       |
| IP Client Linux | `CLIENT_IP`         |
| IP ZeekVM       | `ZEEK_IP`           |
| IP WazuhVM      | `WAZUH_IP`          |
| Timestamp reale | `TIMESTAMP`         |
| UID Zeek        | `UID`               |
| Hash reale      | `HASH_REDACTED`     |
| Hostname reale  | `HOSTNAME_REDACTED` |
| Username reale  | `USER_REDACTED`     |
| Porta listener  | `SCENARIO_PORT`     |
| Path sensibile  | `PATH_REDACTED`     |
| Agent ID        | `AGENT_ID`          |

## Esempio di alert sanificato

```json
{
  "timestamp": "TIMESTAMP",
  "rule": {
    "level": 5,
    "description": "Zeek: Possible Reverse shell (live). uid: UID, source ip: CLIENT_IP, destination ip: ATTACKER_IP, destination port: SCENARIO_PORT.",
    "id": "100910",
    "groups": [
      "zeek_custom",
      "reverse_shell_stage",
      "reverse_shell_start_chain"
    ]
  },
  "agent": {
    "id": "AGENT_ID",
    "name": "ZeekVM",
    "ip": "ZEEK_IP"
  },
  "data": {
    "event_type": "reverse_shell_live",
    "uid": "UID",
    "source_ip": "CLIENT_IP",
    "destination_ip": "ATTACKER_IP",
    "destination_port": "SCENARIO_PORT",
    "payload_type": "PAYLOAD_TYPE_REDACTED"
  },
  "location": "/var/log/zeek-custom/reverse_shell_live.log"
}
```

## Esempio di correlazione sanificata

```json
{
  "timestamp": "TIMESTAMP",
  "rule": {
    "level": 12,
    "description": "Complete reverse shell lifecycle detected. IP detected: ATTACKER_IP. IP victim: CLIENT_IP",
    "id": "110907",
    "groups": [
      "zeek_custom",
      "reverse_shell_chain_without_download"
    ]
  },
  "agent": {
    "id": "AGENT_ID",
    "name": "ZeekVM",
    "ip": "ZEEK_IP"
  },
  "data": {
    "source_ip": "CLIENT_IP",
    "destination_ip": "ATTACKER_IP",
    "uid": "UID"
  },
  "location": "/var/log/zeek-custom/reverse_shell_final.log"
}
```

## Come documentare una evidenza

Ogni evidenza dovrebbe indicare:

* fonte;
* scenario;
* log Zeek di origine;
* rule ID Wazuh;
* cosa dimostra;
* dati sanificati;
* collegamento allo scenario.

Esempio:

```text
Fonte: Wazuh
Scenario: Reverse Shell
Log origine: reverse_shell_live.log
Rule ID: 100910
Descrizione: alert generato da log custom Zeek per possibile reverse shell live
Dati sanificati: IP, UID, timestamp, porta
```

## Relazione con i decoder

Gli alert presenti in questa directory dipendono dai decoder custom documentati in:

```text
blue-team/wazuh/decoders/
```

In particolare:

```text
zeek_decoder_custom.xml
```

## Relazione con le rules

Le regole custom sono documentate in:

```text
blue-team/wazuh/rules/
```

File principali:

```text
002_zeek_rules_custom.xml
003_zeek_correlations.xml
```

## Relazione con lo scenario

La documentazione dello scenario si trova in:

```text
scenarios/reverse-shell/
```

Questa directory contiene invece solo le evidenze Wazuh relative allo scenario.

## Verifiche utili

Sul Wazuh Manager:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

Cercare alert reverse shell:

```bash
sudo grep -i "reverse_shell" /var/ossec/logs/alerts/alerts.json
```

Cercare una rule specifica:

```bash
sudo grep '"id":"100910"' /var/ossec/logs/alerts/alerts.json
```

Cercare correlazioni:

```bash
sudo grep '"id":"110907"' /var/ossec/logs/alerts/alerts.json
```

## Controlli prima del commit

Prima di fare commit, eseguire:

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|payload|exploit" evidence/reverse-shell/wazuh/
```

Controllare anche il diff:

```bash
git diff evidence/reverse-shell/wazuh/
```

## Best practice

* mantenere gli alert piccoli e sanificati;
* includere solo eventi utili alla validazione;
* non caricare file completi da `/var/ossec/logs/`;
* indicare sempre rule ID e log di origine;
* separare alert singoli e correlazioni;
* usare placeholder coerenti;
* collegare ogni evidenza allo scenario Reverse Shell.
