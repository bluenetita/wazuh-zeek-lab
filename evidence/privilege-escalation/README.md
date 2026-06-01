# Privilege Escalation Evidence

Questa directory contiene evidenze sanificate relative allo scenario Privilege Escalation simulato nel cyber range.

## Obiettivo

L'obiettivo di questa directory è raccogliere e documentare le evidenze osservate durante lo scenario Privilege Escalation sul Client Linux.

Le evidenze devono mostrare cosa è stato effettivamente osservato, senza includere exploit, payload, credenziali, comandi offensivi completi o log grezzi non sanificati.

## Scenario di riferimento

| Campo                 | Valore                                      |
| --------------------- | ------------------------------------------- |
| Scenario              | Privilege Escalation                        |
| Stato                 | Completato                                  |
| Target                | Client Linux / ClientVM                     |
| Macchina di controllo | AttackerVM / Kali Linux                     |
| Visibilità principale | Wazuh                                       |
| Visibilità secondaria | Zeek, solo per eventuale traffico correlato |

## Struttura

```text
evidence/privilege-escalation/
├── README.md
└── wazuh/
    └── README.md
```

## Fonti di evidenza

Lo scenario Privilege Escalation produce principalmente evidenze host-based.

| Fonte        | Tipo di evidenza                                              |
| ------------ | ------------------------------------------------------------- |
| Wazuh        | Alert, eventi host-based, FIM, log locali raccolti dall'agent |
| Client Linux | Log locali, modifiche al sistema, attività utente             |
| Zeek         | Eventuale traffico di rete correlato, con visibilità limitata |
| pfSense      | Eventuale traffico attraversato dal firewall                  |
| RouterOS     | Routing del traffico tra segmenti                             |

## Evidenze Wazuh

Wazuh è il componente principale per osservare questo scenario.

Le evidenze possono includere:

* eventi di autenticazione;
* attività utente;
* modifiche a file monitorati;
* eventi File Integrity Monitoring;
* modifiche a permessi o configurazioni;
* alert generati da regole Wazuh;
* log raccolti dall'agent installato sul Client Linux.

## Visibilità Zeek

Zeek ha visibilità limitata in questo scenario perché la Privilege Escalation avviene principalmente sul sistema target.

Zeek può osservare solo traffico di rete correlato, ad esempio:

* connessioni precedenti o successive allo scenario;
* traffico tra AttackerVM e Client Linux;
* eventuali download o trasferimenti;
* traffico di controllo.

Zeek non può osservare direttamente:

* comandi eseguiti localmente;
* cambio di privilegi;
* modifiche a file locali;
* modifiche a permessi;
* creazione di utenti;
* attività sui processi locali.

## Tipi di file ammessi

È possibile aggiungere in questa directory solo evidenze ridotte e sanificate, ad esempio:

```text
wazuh-alert-privilege-escalation-sample.json
fim-event-sample.json
auth-event-sample.txt
notes.md
```

## Tipi di file non ammessi

Non caricare:

* exploit;
* payload;
* malware;
* reverse shell pronte all'uso;
* comandi offensivi completi;
* credenziali;
* token;
* chiavi private;
* dump;
* file generati durante compromissioni;
* log completi;
* `alerts.json` completo;
* `alerts.log` completo;
* `ossec.log` completo;
* PCAP completi.

## Regole di sanificazione

Prima di aggiungere un'evidenza, sostituire valori reali con placeholder.

| Valore reale    | Placeholder         |
| --------------- | ------------------- |
| IP AttackerVM   | `ATTACKER_IP`       |
| IP Client Linux | `CLIENT_IP`         |
| IP WazuhVM      | `WAZUH_IP`          |
| Timestamp reale | `TIMESTAMP`         |
| Hostname reale  | `HOSTNAME_REDACTED` |
| Username reale  | `USER_REDACTED`     |
| Path sensibile  | `PATH_REDACTED`     |
| Hash reale      | `HASH_REDACTED`     |

## Come documentare una evidenza

Ogni evidenza dovrebbe indicare:

* fonte;
* scenario collegato;
* cosa dimostra;
* evento o alert osservato;
* eventuale regola Wazuh coinvolta;
* dati rimossi o sanificati.

Esempio:

```text
Fonte: Wazuh
Scenario: Privilege Escalation
Descrizione: evento host-based osservato sul Client Linux
Dati sanificati: IP, hostname, username, path locali
```

## Collegamenti utili

| Directory                               | Descrizione                            |
| --------------------------------------- | -------------------------------------- |
| `../../scenarios/privilege-escalation/` | Documentazione dello scenario          |
| `../../infrastructure/client-linux/`    | Documentazione del target Client Linux |
| `../../red-team/attacker-kali/`         | Documentazione AttackerVM              |
| `../../blue-team/wazuh/`                | Configurazione Wazuh                   |
| `../../blue-team/zeek/`                 | Configurazione Zeek                    |

## Controlli prima del commit

Prima di fare commit, eseguire:

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|payload|exploit" evidence/privilege-escalation/
```

Controllare anche il diff:

```bash
git diff evidence/privilege-escalation/
```

## Note operative

Questa directory deve contenere solo evidenze utili alla validazione dello scenario.

Non deve contenere materiale offensivo o file runtime completi.

## Best practice

* mantenere le evidenze piccole;
* usare placeholder coerenti;
* non caricare log grezzi;
* documentare cosa dimostra ogni evidenza;
* separare evidenze Wazuh da eventuali note host-based;
* aggiornare questa directory solo con risultati realmente osservati.
