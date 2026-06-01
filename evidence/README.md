# Evidence

Questa directory contiene evidenze sanificate raccolte durante gli scenari simulati nel cyber range.

## Obiettivo

La directory `evidence/` serve a documentare i risultati osservati durante gli scenari, mantenendo separata la descrizione dello scenario dalle prove raccolte.

Le evidenze incluse devono essere ridotte, sanificate e utili alla comprensione del lavoro svolto.

## Scenari documentati

| Scenario             | Directory               | Tipologia evidenze          |
| -------------------- | ----------------------- | --------------------------- |
| Reverse Shell        | `reverse-shell/`        | Evidenze Zeek e Wazuh       |
| Privilege Escalation | `privilege-escalation/` | Evidenze Wazuh e host-based |

## Differenza tra scenarios ed evidence

La directory `scenarios/` descrive cosa è stato simulato, quali VM sono state coinvolte e quali risultati erano attesi.

La directory `evidence/` documenta cosa è stato effettivamente osservato.

```text
scenarios/   -> descrizione dello scenario
evidence/    -> evidenze sanificate raccolte durante lo scenario
```

## Struttura

```text
evidence/
├── README.md
├── reverse-shell/
│   ├── README.md
│   ├── zeek/
│   └── wazuh/
└── privilege-escalation/
    ├── README.md
    └── wazuh/
```

## Tipi di evidenze ammesse

È possibile includere:

* estratti ridotti di log Zeek;
* alert Wazuh sanificati;
* screenshot non sensibili;
* output sintetici di comandi;
* note di validazione;
* tabelle riassuntive dei risultati.

## Tipi di evidenze non ammesse

Non caricare:

* log completi;
* `alerts.json` completo;
* `alerts.log` completo;
* `ossec.log` completo;
* PCAP completi;
* payload;
* exploit;
* malware;
* reverse shell pronte all'uso;
* credenziali;
* token;
* chiavi private;
* dump;
* file generati durante compromissioni;
* dati personali;
* IP pubblici sensibili.

## Regole di sanificazione

Prima di aggiungere un'evidenza, sostituire eventuali dati sensibili con placeholder.

| Valore reale       | Placeholder         |
| ------------------ | ------------------- |
| IP AttackerVM      | `ATTACKER_IP`       |
| IP Client Linux    | `CLIENT_IP`         |
| IP ZeekVM          | `ZEEK_IP`           |
| IP WazuhVM         | `WAZUH_IP`          |
| Timestamp reale    | `TIMESTAMP`         |
| UID Zeek           | `UID`               |
| Hash reale         | `HASH_REDACTED`     |
| Hostname sensibile | `HOSTNAME_REDACTED` |
| Username reale     | `USER_REDACTED`     |
| Path sensibile     | `PATH_REDACTED`     |

## Reverse Shell

Lo scenario Reverse Shell può produrre evidenze da Zeek e Wazuh.

| Fonte    | Evidenza possibile                                       |
| -------- | -------------------------------------------------------- |
| Zeek     | Connessioni, log custom, traffico persistente            |
| Wazuh    | Alert custom, correlazioni, eventi raccolti dai log Zeek |
| pfSense  | Eventuale traffico permesso o bloccato                   |
| RouterOS | Routing tra rete interna ed esterna                      |

Le evidenze relative a questo scenario sono organizzate in:

```text
evidence/reverse-shell/
```

## Privilege Escalation

Lo scenario Privilege Escalation produce principalmente evidenze host-based.

| Fonte        | Evidenza possibile                                     |
| ------------ | ------------------------------------------------------ |
| Wazuh        | Eventi locali, log di sistema, possibili eventi FIM    |
| Client Linux | Log locali e attività sul sistema                      |
| Zeek         | Visibilità limitata, solo eventuale traffico correlato |

Le evidenze relative a questo scenario sono organizzate in:

```text
evidence/privilege-escalation/
```

## Come aggiungere una nuova evidenza

Ogni evidenza dovrebbe avere:

* scenario di riferimento;
* fonte dell'evidenza;
* breve descrizione;
* data o fase dello scenario, se utile;
* dati sensibili rimossi o sostituiti;
* collegamento alla regola, decoder o componente che l'ha generata.

Esempio di naming:

```text
wazuh-alert-reverse-shell-sample.json
zeek-conn-reverse-shell-sample.log
fim-event-privilege-escalation-sample.json
```

## Controlli prima del commit

Prima di fare commit, eseguire:

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|cvv|iban|payload|exploit" evidence/
```

Controllare anche il diff:

```bash
git diff evidence/
```

## Cosa versionare

È possibile versionare:

* esempi piccoli e sanificati;
* alert Wazuh ridotti;
* log Zeek ridotti;
* note di validazione;
* screenshot senza dati sensibili;
* risultati sintetici.

## Cosa non versionare

Non versionare:

* archivi completi di log;
* file `.pcap` o `.pcapng`;
* payload;
* exploit;
* malware;
* credenziali;
* dump;
* dati personali;
* file runtime;
* output non controllati.

## Best practice

* mantenere le evidenze piccole;
* includere solo dati utili alla validazione;
* usare placeholder coerenti;
* non caricare log grezzi completi;
* collegare ogni evidenza allo scenario corrispondente;
* documentare cosa dimostra ogni evidenza;
* mantenere separati log Zeek e alert Wazuh.
