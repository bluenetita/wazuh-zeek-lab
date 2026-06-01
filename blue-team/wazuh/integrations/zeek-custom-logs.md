# Zeek Custom Logs Integration

Questo documento descrive l'integrazione tra Zeek e Wazuh per la raccolta e l'analisi dei log Zeek standard e custom.

## Obiettivo

L'obiettivo dell'integrazione è permettere a Wazuh di ricevere eventi generati da Zeek e trasformarli in alert tramite decoder e regole custom.

Zeek fornisce visibilità a livello rete.

Wazuh fornisce visibilità host-based e capacità di alerting/correlazione.

La combinazione dei due strumenti permette di correlare eventi di rete con eventi osservati sugli host.

## Flusso generale

```text
Traffico di rete
   |
   v
Zeek
   |
   v
Log standard e custom
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

## Componenti coinvolti

| Componente            | Ruolo                                  |
| --------------------- | -------------------------------------- |
| Zeek                  | Analizza traffico di rete e genera log |
| Wazuh Agent su ZeekVM | Legge i log Zeek e li invia al manager |
| Wazuh Manager         | Riceve eventi, applica decoder e rules |
| Decoder Wazuh         | Estrae campi dai log JSON              |
| Rules Wazuh           | Generano alert e correlazioni          |
| Logrotate             | Gestisce rotazione dei log custom Zeek |

## Percorsi dei log Zeek

### Log Zeek standard

I log standard Zeek vengono letti da:

```text
/opt/zeek/logs/current/*.log
```

Questi log possono includere:

* `conn.log`;
* `dns.log`;
* `http.log`;
* `ssl.log`;
* `tls.log`;
* `notice.log`;
* `weird.log`.

### Log Zeek custom

I log custom Zeek vengono salvati in:

```text
/var/log/zeek-custom/
```

I log custom principali sono:

| Log                          | Descrizione                                           |
| ---------------------------- | ----------------------------------------------------- |
| `possible_malware.log`       | Possibile download o trasferimento sospetto           |
| `reverse_shell_live.log`     | Possibile reverse shell in corso                      |
| `reverse_shell_final.log`    | Chiusura o classificazione finale della reverse shell |
| `reverse_shell_movement.log` | Traffico o movimento associato alla reverse shell     |

## Configurazione Wazuh Agent

L'agent Wazuh installato su ZeekVM legge i log Zeek tramite blocchi `localfile`.

La configurazione completa dell'agent è documentata in:

```text
blue-team/wazuh/agent-configs/zeek-agent-ossec.conf
```

Blocchi principali:

```xml
<localfile>
  <log_format>json</log_format>
  <location>/opt/zeek/logs/current/*.log</location>
  <only-future-events>no</only-future-events>
</localfile>
```

```xml
<localfile>
  <log_format>json</log_format>
  <location>/var/log/zeek-custom/possible_malware.log</location>
  <only-future-events>no</only-future-events>
</localfile>

<localfile>
  <log_format>json</log_format>
  <location>/var/log/zeek-custom/reverse_shell_live.log</location>
  <only-future-events>no</only-future-events>
</localfile>

<localfile>
  <log_format>json</log_format>
  <location>/var/log/zeek-custom/reverse_shell_final.log</location>
  <only-future-events>no</only-future-events>
</localfile>

<localfile>
  <log_format>json</log_format>
  <location>/var/log/zeek-custom/reverse_shell_movement.log</location>
  <only-future-events>no</only-future-events>
</localfile>
```

## Log format

I log Zeek sono trattati da Wazuh come log JSON.

Per questo motivo viene usato:

```xml
<log_format>json</log_format>
```

Questo permette ai decoder custom di estrarre campi come:

* `event_type`;
* `uid`;
* `source_ip`;
* `destination_ip`;
* `destination_port`;
* `file_name`;
* `mime_type`;
* `sha1`;
* `sha256`;
* `duration`;
* `origin_bytes`;
* `response_bytes`;
* `origin_packets`;
* `response_packets`.

## Decoder coinvolti

I decoder sono presenti in:

```text
blue-team/wazuh/decoders/
```

File principali:

| File                      | Scopo                         |
| ------------------------- | ----------------------------- |
| `zeek_decoders.xml`       | Decoder per log Zeek standard |
| `zeek_decoder_custom.xml` | Decoder per log custom Zeek   |

## Rules coinvolte

Le regole sono presenti in:

```text
blue-team/wazuh/rules/
```

File principali:

| File                        | Scopo                                    |
| --------------------------- | ---------------------------------------- |
| `001_zeek_rules.xml`        | Regole per log Zeek standard             |
| `002_zeek_rules_custom.xml` | Regole per log custom Zeek               |
| `003_zeek_correlations.xml` | Regole di correlazione per reverse shell |

## Regole custom principali

|  Rule ID | Log sorgente                 | Descrizione                                 |
| -------: | ---------------------------- | ------------------------------------------- |
| `100909` | `possible_malware.log`       | Possibile download o trasferimento sospetto |
| `100910` | `reverse_shell_live.log`     | Possibile reverse shell live                |
| `100911` | `reverse_shell_final.log`    | Possibile reverse shell chiusa              |
| `100912` | `reverse_shell_movement.log` | Traffico compatibile con reverse shell      |

## Correlazioni principali

Le regole di correlazione ricostruiscono sequenze di eventi.

### Catena con download malware

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

Regole coinvolte:

|  Rule ID | Descrizione                                        |
| -------: | -------------------------------------------------- |
| `110900` | Malware download seguito da avvio reverse shell    |
| `110901` | Malware download seguito da traffico reverse shell |
| `110902` | Ciclo completo reverse shell dopo malware download |

### Catena senza download malware

```text
reverse_shell_live
   |
   v
reverse_shell_movement
   |
   v
reverse_shell_final
```

Regole coinvolte:

|  Rule ID | Descrizione                                         |
| -------: | --------------------------------------------------- |
| `110906` | Reverse shell start seguita da traffico             |
| `110907` | Ciclo completo reverse shell senza malware download |

## Logrotate

I log custom Zeek sono ruotati tramite `logrotate`.

Configurazione documentata in:

```text
blue-team/zeek/logrotate/
```

Percorso gestito:

```text
/var/log/zeek-custom/*.log
```

Configurazione attuale:

```conf
/var/log/zeek-custom/*.log {
    daily
    rotate 14
    compress
    missingok
    notifempty
    copytruncate
    create 0640 zeek wazuh
}
```

Questa configurazione mantiene i log leggibili dal gruppo `wazuh`.

## Permessi

Per permettere a Wazuh di leggere i log custom Zeek, i file devono essere accessibili al gruppo `wazuh`.

Configurazione prevista:

| Proprietà | Valore  |
| --------- | ------- |
| Owner     | `zeek`  |
| Gruppo    | `wazuh` |
| Permessi  | `0640`  |

Verifica:

```bash
ls -lh /var/log/zeek-custom/
```

## Verifiche operative

### Verificare che Zeek scriva i log custom

```bash
ls -lh /var/log/zeek-custom/
tail -f /var/log/zeek-custom/reverse_shell_live.log
```

### Verificare che l'agent Wazuh sia attivo su ZeekVM

```bash
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
```

### Verificare il manager Wazuh

Sul Wazuh Manager:

```bash
sudo systemctl status wazuh-manager
sudo tail -f /var/ossec/logs/ossec.log
```

### Verificare gli alert

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.log
```

oppure:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

## Troubleshooting

### Wazuh non riceve eventi Zeek

Verificare:

* stato dell'agent su ZeekVM;
* connessione tra agent e manager;
* configurazione `localfile`;
* path dei log;
* permessi dei file;
* presenza di eventi nei log custom;
* errori in `/var/ossec/logs/ossec.log`.

### Decoder non estrae i campi

Verificare:

* formato JSON del log;
* nomi dei campi generati da Zeek;
* regex del decoder;
* errori nel log del manager;
* corrispondenza tra decoder e rules.

### Rules non generano alert

Verificare:

* rule ID;
* `if_sid`;
* `if_matched_sid`;
* campi usati nelle condizioni;
* livello della rule;
* gruppi associati;
* eventuali regole con livello `0` che sopprimono eventi.

### Correlazione non funziona

Verificare:

* timestamp degli eventi;
* ordine degli eventi;
* presenza di campi comuni;
* `same_field`;
* `different_field`;
* `timeframe`;
* rule precedenti nella catena.

## Relazione con gli scenari

| Scenario               | Evidenza Zeek                | Alert Wazuh              |
| ---------------------- | ---------------------------- | ------------------------ |
| Malware download       | `possible_malware.log`       | Rule `100909`            |
| Reverse shell live     | `reverse_shell_live.log`     | Rule `100910`            |
| Reverse shell traffic  | `reverse_shell_movement.log` | Rule `100912`            |
| Reverse shell final    | `reverse_shell_final.log`    | Rule `100911`            |
| Reverse shell completa | Sequenza di log custom       | Rule `110902` o `110907` |

## Cosa non caricare

Non caricare nella repository:

* log reali completi;
* alert completi;
* PCAP;
* payload;
* malware;
* password;
* token;
* chiavi private;
* file `client.keys`;
* file `authd.pass`.

## Best practice

* mantenere coerenti script Zeek, decoder Wazuh e rules Wazuh;
* testare ogni log custom con un evento controllato;
* verificare i permessi dopo la rotazione dei log;
* documentare ogni rule ID;
* usare esempi sanificati in `blue-team/wazuh/log-samples/`;
* non duplicare inutilmente configurazioni già presenti in `agent-configs/`;
* aggiornare questo documento quando cambiano path, log custom, decoder o rules.
