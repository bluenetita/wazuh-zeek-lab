# Wazuh Rules

Questa directory contiene le regole XML custom utilizzate da Wazuh per generare alert a partire dai log Zeek standard e custom.

## Obiettivo

Le regole Wazuh servono ad analizzare gli eventi normalizzati dai decoder e generare alert in base a condizioni specifiche.

Nel laboratorio, le regole sono usate per:

* analizzare log Zeek standard;
* rilevare query DNS;
* rilevare connessioni rifiutate;
* rilevare possibili attività di port scanning;
* rilevare certificati TLS sospetti;
* rilevare download sospetti;
* rilevare possibili reverse shell;
* correlare più eventi appartenenti alla stessa catena di attacco.

## File presenti

| File                        | Descrizione                              |
| --------------------------- | ---------------------------------------- |
| `README.md`                 | Questo file                              |
| `001_zeek_rules.xml`        | Regole per log Zeek standard             |
| `002_zeek_rules_custom.xml` | Regole per log custom Zeek               |
| `003_zeek_correlations.xml` | Regole di correlazione per reverse shell |

## 001_zeek_rules.xml

Questo file contiene regole relative ai log Zeek standard.

Le regole principali includono:

|  Rule ID | Livello | Descrizione                                         |
| -------: | ------: | --------------------------------------------------- |
| `100900` |       0 | Regola base per eventi Zeek decodificati come JSON  |
| `100901` |       5 | Query DNS osservata da Zeek                         |
| `100902` |       0 | Soppressione traffico mDNS normale                  |
| `100903` |       7 | Connessione rifiutata                               |
| `100904` |      10 | Connessioni rifiutate multiple, possibile port scan |
| `100905` |       0 | Esclusione query DNS verso dominio CTI Wazuh        |
| `100906` |       8 | Connessione TLS con certificato self-signed         |
| `100907` |      12 | Connessione TLS con certificato scaduto             |

## 002_zeek_rules_custom.xml

Questo file contiene regole per i log custom generati dagli script Zeek del laboratorio.

Le regole principali includono:

|  Rule ID | Livello | Log sorgente                 | Descrizione                                 |
| -------: | ------: | ---------------------------- | ------------------------------------------- |
| `100909` |       5 | `possible_malware.log`       | Possibile download o trasferimento sospetto |
| `100910` |       5 | `reverse_shell_live.log`     | Possibile reverse shell live                |
| `100911` |       5 | `reverse_shell_final.log`    | Possibile reverse shell chiusa              |
| `100912` |       5 | `reverse_shell_movement.log` | Traffico compatibile con reverse shell      |

## 003_zeek_correlations.xml

Questo file contiene regole di correlazione per collegare più eventi Zeek custom.

L'obiettivo è ricostruire una possibile catena di reverse shell.

## Catena con download malware

Questa catena considera il caso in cui venga osservato prima un possibile download malevolo e poi una reverse shell.

|  Rule ID | Livello | Descrizione                                        |
| -------: | ------: | -------------------------------------------------- |
| `110900` |       9 | Malware download seguito da avvio reverse shell    |
| `110901` |      10 | Malware download seguito da traffico reverse shell |
| `110902` |      12 | Ciclo completo reverse shell dopo malware download |

Flusso logico:

```text
possible_malware
   |
   v
reverse_shell_live
   |
   v
reverse_shell_movement
   |
   v
reverse_shell_final
```

## Catena senza download malware

Questa catena considera il caso in cui venga osservata una reverse shell senza un precedente evento di download malware.

|  Rule ID | Livello | Descrizione                                         |
| -------: | ------: | --------------------------------------------------- |
| `110903` |       9 | Multiple reverse shell con stessi IP                |
| `110904` |      10 | Multiple reverse shell seguite da traffico          |
| `110905` |      12 | Ciclo completo reverse shell multipla               |
| `110906` |      10 | Reverse shell start seguita da traffico             |
| `110907` |      12 | Ciclo completo reverse shell senza malware download |

Flusso logico:

```text
reverse_shell_live
   |
   v
reverse_shell_movement
   |
   v
reverse_shell_final
```

## Relazione con i decoder

Le regole presenti in questa directory dipendono dai decoder definiti in:

```text
blue-team/wazuh/decoders/
```

In particolare:

| Decoder                   | Regole collegate                                         |
| ------------------------- | -------------------------------------------------------- |
| `zeek_decoders.xml`       | `001_zeek_rules.xml`                                     |
| `zeek_decoder_custom.xml` | `002_zeek_rules_custom.xml`, `003_zeek_correlations.xml` |

Se cambia il nome di un campo estratto dal decoder, devono essere aggiornate anche le rules.

## Relazione con Zeek

Le regole custom dipendono dai log prodotti dagli script Zeek.

I log custom principali sono:

```text
/var/log/zeek-custom/possible_malware.log
/var/log/zeek-custom/reverse_shell_live.log
/var/log/zeek-custom/reverse_shell_final.log
/var/log/zeek-custom/reverse_shell_movement.log
```

Questi log vengono raccolti dall'agent Wazuh installato sulla VM Zeek.

## Relazione con gli scenari

| Scenario                            | File rules coinvolto        |
| ----------------------------------- | --------------------------- |
| DNS analysis                        | `001_zeek_rules.xml`        |
| Port scan / rejected connections    | `001_zeek_rules.xml`        |
| TLS certificate anomalies           | `001_zeek_rules.xml`        |
| Malware download                    | `002_zeek_rules_custom.xml` |
| Reverse shell                       | `002_zeek_rules_custom.xml` |
| Reverse shell lifecycle correlation | `003_zeek_correlations.xml` |

## Percorso di installazione

Sul Wazuh Manager, le regole custom possono essere copiate in:

```text
/var/ossec/etc/rules/
```

Esempio:

```bash
sudo cp blue-team/wazuh/rules/001_zeek_rules.xml /var/ossec/etc/rules/
sudo cp blue-team/wazuh/rules/002_zeek_rules_custom.xml /var/ossec/etc/rules/
sudo cp blue-team/wazuh/rules/003_zeek_correlations.xml /var/ossec/etc/rules/
```

Dopo la copia, riavviare il manager:

```bash
sudo systemctl restart wazuh-manager
```

## Verifiche

Controllare eventuali errori:

```bash
sudo grep -iE "error|rule|decoder" /var/ossec/logs/ossec.log
```

Controllare lo stato del manager:

```bash
sudo systemctl status wazuh-manager
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

* Dopo ogni modifica alle regole, riavviare il Wazuh Manager.
* Verificare sempre `/var/ossec/logs/ossec.log` dopo il riavvio.
* Le rule ID custom devono evitare conflitti con altre regole.
* Le regole di correlazione dipendono da timestamp, campi comuni e ordine degli eventi.
* Se cambiano i log custom Zeek, aggiornare decoder e rules.

## Cosa non caricare

Non caricare:

* alert reali completi;
* log completi;
* dati personali;
* credenziali;
* token;
* chiavi private;
* output non sanificati.

Questa directory deve contenere solo regole XML e documentazione.

## Best practice

* mantenere separate regole standard, custom e correlation;
* usare nomi file ordinati numericamente;
* documentare ogni rule ID;
* collegare ogni regola allo scenario corrispondente;
* testare le regole con eventi controllati;
* mantenere coerenti Zeek scripts, Wazuh decoders e Wazuh rules.
