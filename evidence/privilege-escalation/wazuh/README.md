# Wazuh Evidence - Privilege Escalation

Questa directory contiene evidenze sanificate prodotte da Wazuh durante lo scenario Privilege Escalation.

## Obiettivo

L'obiettivo è documentare le evidenze host-based osservate sul Client Linux durante lo scenario di Privilege Escalation.

In questo scenario Wazuh è la fonte principale di visibilità, perché l'attività avviene soprattutto a livello locale sul sistema target.

## Scenario di riferimento

| Campo                 | Valore                  |
| --------------------- | ----------------------- |
| Scenario              | Privilege Escalation    |
| Target                | Client Linux / ClientVM |
| Macchina di controllo | AttackerVM / Kali Linux |
| Fonte principale      | Wazuh                   |
| Tipo evidenza         | Host-based              |
| Stato                 | Completato              |

## Ruolo di Wazuh

Wazuh può osservare eventi locali generati dal Client Linux, ad esempio:

* eventi di autenticazione;
* attività utente;
* modifiche a file o directory;
* eventi File Integrity Monitoring;
* modifiche a permessi;
* log di sistema;
* alert generati da regole Wazuh.

## Tipi di evidenze ammesse

È possibile includere in questa directory esempi piccoli e sanificati come:

```text
wazuh-alert-privilege-escalation-sample.json
fim-event-sample.json
auth-event-sample.txt
syscheck-event-sample.json
notes.md
```

## Tipi di evidenze non ammesse

Non caricare:

* `alerts.json` completo;
* `alerts.log` completo;
* `ossec.log` completo;
* log grezzi completi;
* dump;
* payload;
* exploit;
* malware;
* comandi offensivi completi;
* credenziali;
* token;
* chiavi private;
* dati personali;
* file generati durante compromissioni.

## Placeholder consigliati

Prima di inserire una evidenza, sostituire i dati reali con placeholder.

| Valore reale          | Placeholder         |
| --------------------- | ------------------- |
| IP Client Linux       | `CLIENT_IP`         |
| IP AttackerVM         | `ATTACKER_IP`       |
| IP WazuhVM            | `WAZUH_IP`          |
| Hostname reale        | `HOSTNAME_REDACTED` |
| Username reale        | `USER_REDACTED`     |
| Path sensibile        | `PATH_REDACTED`     |
| Timestamp reale       | `TIMESTAMP`         |
| Hash reale            | `HASH_REDACTED`     |
| Rule ID non rilevante | `RULE_ID`           |

## Esempio di alert sanificato

```json
{
  "timestamp": "TIMESTAMP",
  "rule": {
    "level": 7,
    "description": "File added to the system.",
    "id": "RULE_ID",
    "groups": [
      "syscheck",
      "fim"
    ]
  },
  "agent": {
    "id": "AGENT_ID",
    "name": "ClientVM",
    "ip": "CLIENT_IP"
  },
  "syscheck": {
    "path": "PATH_REDACTED",
    "event": "added",
    "mode": "realtime"
  },
  "location": "syscheck"
}
```

## Come documentare una evidenza

Ogni evidenza dovrebbe indicare:

* fonte;
* scenario;
* host coinvolto;
* cosa dimostra;
* eventuale rule ID Wazuh;
* dati sanificati;
* collegamento allo scenario.

Esempio:

```text
Fonte: Wazuh
Scenario: Privilege Escalation
Host: Client Linux
Descrizione: evento FIM osservato durante attività locale controllata
Dati sanificati: username, path, timestamp, IP
```

## Relazione con lo scenario

La documentazione dello scenario si trova in:

```text
scenarios/privilege-escalation/
```

Questa directory contiene invece solo le evidenze Wazuh relative allo scenario.

## Relazione con Client Linux

Il target dello scenario è documentato in:

```text
infrastructure/client-linux/
```

Se vengono aggiunti eventi o configurazioni specifiche dell'agent Wazuh sul Client Linux, documentarli anche nella sezione appropriata.

## Verifiche utili

Sul Wazuh Manager:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

oppure:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.log
```

Per cercare eventi relativi al Client Linux:

```bash
sudo grep -i "ClientVM" /var/ossec/logs/alerts/alerts.json
```

Per cercare eventi FIM:

```bash
sudo grep -i "syscheck" /var/ossec/logs/alerts/alerts.json
```

## Controlli prima del commit

Prima di fare commit, eseguire:

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|payload|exploit" evidence/privilege-escalation/wazuh/
```

Controllare anche il diff:

```bash
git diff evidence/privilege-escalation/wazuh/
```

## Best practice

* mantenere le evidenze piccole;
* usare placeholder coerenti;
* non caricare log completi;
* non includere comandi offensivi;
* documentare cosa dimostra ogni evidenza;
* collegare ogni alert allo scenario Privilege Escalation;
* distinguere evidenze FIM, autenticazione e log di sistema.
