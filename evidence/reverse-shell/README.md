# Reverse Shell Evidence

Questa directory contiene evidenze sanificate relative allo scenario Reverse Shell simulato nel cyber range.

## Obiettivo

L'obiettivo di questa directory è raccogliere e documentare le evidenze osservate durante lo scenario Reverse Shell tra Client Linux e AttackerVM.

Le evidenze devono mostrare cosa è stato effettivamente osservato da Zeek e Wazuh, senza includere payload, exploit, reverse shell funzionanti, credenziali o log grezzi completi.

## Scenario di riferimento

| Campo                 | Valore                  |
| --------------------- | ----------------------- |
| Scenario              | Reverse Shell           |
| Stato                 | Completato              |
| Target                | Client Linux / ClientVM |
| Macchina attaccante   | AttackerVM / Kali Linux |
| Visibilità principale | Zeek                    |
| Correlazione alert    | Wazuh                   |

## Struttura

```text
evidence/reverse-shell/
├── README.md
├── zeek/
│   └── README.md
└── wazuh/
    └── README.md
```

## Fonti di evidenza

Lo scenario Reverse Shell produce evidenze principalmente da Zeek e Wazuh.

| Fonte    | Tipo di evidenza                                         |
| -------- | -------------------------------------------------------- |
| Zeek     | Connessioni TCP, log custom, traffico persistente        |
| Wazuh    | Alert custom, correlazioni, eventi raccolti dai log Zeek |
| pfSense  | Eventuale traffico permesso o bloccato                   |
| RouterOS | Routing tra rete esterna simulata e VLAN Client          |

## Evidenze Zeek

Zeek osserva il traffico di rete associato allo scenario.

Evidenze possibili:

* connessione TCP tra Client Linux e AttackerVM;
* durata della connessione;
* IP sorgente e destinazione;
* porte coinvolte;
* byte trasferiti;
* log custom collegati alla reverse shell;
* eventuale evento di download o trasferimento sospetto.

Le evidenze Zeek sono organizzate in:

```text
evidence/reverse-shell/zeek/
```

## Evidenze Wazuh

Wazuh riceve i log custom Zeek tramite l'agent installato sulla VM Zeek e applica decoder e rules custom.

Evidenze possibili:

* alert per `possible_malware`;
* alert per `reverse_shell_live`;
* alert per `reverse_shell_movement`;
* alert per `reverse_shell_final`;
* alert di correlazione sul ciclo completo della reverse shell.

Le evidenze Wazuh sono organizzate in:

```text
evidence/reverse-shell/wazuh/
```

## Log custom collegati

I log custom Zeek relativi allo scenario sono:

| Log                          | Descrizione                                         |
| ---------------------------- | --------------------------------------------------- |
| `possible_malware.log`       | Possibile download o trasferimento sospetto         |
| `reverse_shell_live.log`     | Possibile reverse shell in corso                    |
| `reverse_shell_movement.log` | Traffico associato alla connessione                 |
| `reverse_shell_final.log`    | Chiusura o classificazione finale della connessione |

## Regole Wazuh collegate

Le evidenze Wazuh possono essere collegate alle seguenti rules custom:

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

## Tipi di file ammessi

È possibile aggiungere evidenze piccole e sanificate, ad esempio:

```text
zeek-conn-reverse-shell-sample.log
zeek-custom-reverse-shell-live-sample.log
zeek-custom-reverse-shell-final-sample.log
wazuh-alert-reverse-shell-sample.json
wazuh-correlation-reverse-shell-sample.json
notes.md
```

## Tipi di file non ammessi

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
* log completi;
* `alerts.json` completo;
* `alerts.log` completo;
* PCAP completi.

## Regole di sanificazione

Prima di aggiungere una evidenza, sostituire valori reali con placeholder.

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

## Come documentare una evidenza

Ogni evidenza dovrebbe indicare:

* fonte;
* scenario;
* host coinvolti;
* cosa dimostra;
* eventuale rule ID Wazuh;
* log Zeek o alert Wazuh di origine;
* dati sanificati;
* collegamento allo scenario.

Esempio:

```text
Fonte: Zeek
Scenario: Reverse Shell
Host coinvolti: Client Linux, AttackerVM
Descrizione: connessione persistente osservata tra target e macchina attaccante
Dati sanificati: IP, timestamp, UID, porta
```

## Collegamenti utili

| Directory                            | Descrizione                            |
| ------------------------------------ | -------------------------------------- |
| `../../scenarios/reverse-shell/`     | Documentazione dello scenario          |
| `../../infrastructure/client-linux/` | Documentazione del target Client Linux |
| `../../red-team/attacker-kali/`      | Documentazione AttackerVM              |
| `../../blue-team/zeek/`              | Configurazione Zeek                    |
| `../../blue-team/wazuh/`             | Configurazione Wazuh, decoder e rules  |
| `../../proxmox/ovs/`                 | Configurazione del mirroring OVS       |

## Controlli prima del commit

Prima di fare commit, eseguire:

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|payload|exploit" evidence/reverse-shell/
```

Controllare anche il diff:

```bash
git diff evidence/reverse-shell/
```

## Note operative

Questa directory deve contenere solo evidenze utili alla validazione dello scenario Reverse Shell.

Non deve contenere materiale offensivo o file runtime completi.

## Best practice

* mantenere le evidenze piccole;
* separare evidenze Zeek e Wazuh;
* usare placeholder coerenti;
* non caricare log completi;
* non includere payload o comandi offensivi;
* documentare cosa dimostra ogni evidenza;
* collegare ogni evidenza allo scenario Reverse Shell.
