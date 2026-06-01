# Zeek Logrotate Configuration

Questa directory contiene la configurazione `logrotate` utilizzata per gestire la rotazione dei log custom generati da Zeek.

## Obiettivo

Gli script custom di Zeek generano log aggiuntivi rispetto ai log standard.

Nel laboratorio questi log vengono salvati in:

```text
/var/log/zeek-custom/
```

La rotazione dei log serve a:

* evitare che i file crescano indefinitamente;
* mantenere uno storico limitato;
* comprimere i log più vecchi;
* preservare permessi compatibili con Zeek e Wazuh;
* permettere a Wazuh di continuare a leggere i log custom.

## File presenti

| File               | Descrizione                                    |
| ------------------ | ---------------------------------------------- |
| `README.md`        | Questo file                                    |
| `zeek-custom-logs` | Configurazione logrotate per i log custom Zeek |

## Configurazione attuale

La configurazione attuale ruota tutti i file `.log` presenti nella directory:

```text
/var/log/zeek-custom/
```

Configurazione:

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

## Significato delle direttive

| Direttiva                    | Significato                                                       |
| ---------------------------- | ----------------------------------------------------------------- |
| `/var/log/zeek-custom/*.log` | Applica la rotazione a tutti i log custom Zeek                    |
| `daily`                      | Ruota i log ogni giorno                                           |
| `rotate 14`                  | Mantiene 14 rotazioni                                             |
| `compress`                   | Comprime i log ruotati                                            |
| `missingok`                  | Non genera errore se un file non esiste                           |
| `notifempty`                 | Non ruota file vuoti                                              |
| `copytruncate`               | Copia il log e poi svuota il file originale                       |
| `create 0640 zeek wazuh`     | Ricrea il file con owner `zeek`, gruppo `wazuh` e permessi `0640` |

## Perché usare `copytruncate`

`copytruncate` è utile perché il processo che scrive il log può continuare a usare lo stesso file.

Nel laboratorio questa scelta aiuta a:

* evitare riavvii di Zeek dopo la rotazione;
* non interrompere la scrittura dei log custom;
* mantenere stabile il percorso monitorato da Wazuh;
* ridurre il rischio che Wazuh perda eventi dopo la rotazione.

## Permessi

La direttiva:

```conf
create 0640 zeek wazuh
```

permette di creare nuovi file log con:

| Campo    | Valore  |
| -------- | ------- |
| Owner    | `zeek`  |
| Gruppo   | `wazuh` |
| Permessi | `0640`  |

Questo è utile perché:

* l'utente `zeek` può scrivere i log;
* il gruppo `wazuh` può leggerli;
* altri utenti non hanno accesso ai log.

## Relazione con Zeek

I log custom sono generati dagli script Zeek presenti in:

```text
blue-team/zeek/site/scripts/
```

Esempi di log custom:

```text
possible_malware.log
reverse_shell_live.log
reverse_shell_movement.log
reverse_shell_final.log
```

## Relazione con Wazuh

Wazuh può leggere i log custom Zeek da:

```text
/var/log/zeek-custom/
```

La rotazione deve quindi mantenere:

* percorso stabile;
* permessi leggibili dal gruppo `wazuh`;
* continuità nella scrittura dei log;
* compatibilità con eventuali decoder e regole custom.

## Installazione

Copiare il file di configurazione nella directory di `logrotate`:

```bash
sudo cp blue-team/zeek/logrotate/zeek-custom-logs /etc/logrotate.d/zeek-custom-logs
```

Verificare il file installato:

```bash
ls -l /etc/logrotate.d/zeek-custom-logs
```

## Test della configurazione

Verificare la configurazione senza applicare modifiche:

```bash
sudo logrotate -d /etc/logrotate.d/zeek-custom-logs
```

Forzare una rotazione di test:

```bash
sudo logrotate -f /etc/logrotate.d/zeek-custom-logs
```

## Verifiche

Controllare i log custom:

```bash
ls -lh /var/log/zeek-custom/
```

Controllare eventuali log compressi:

```bash
ls -lh /var/log/zeek-custom/*.gz
```

Controllare lo stato di logrotate:

```bash
sudo cat /var/lib/logrotate/status | grep zeek
```

Verificare che Wazuh possa leggere i log:

```bash
sudo -u wazuh ls -lh /var/log/zeek-custom/
```

## Troubleshooting

### I log non vengono ruotati

Verificare la configurazione:

```bash
sudo logrotate -d /etc/logrotate.d/zeek-custom-logs
```

Controllare che i file esistano:

```bash
ls -lh /var/log/zeek-custom/*.log
```

### I file ruotati hanno permessi errati

Verificare la direttiva:

```conf
create 0640 zeek wazuh
```

Controllare owner e gruppo:

```bash
ls -lh /var/log/zeek-custom/
```

### Wazuh non legge più i log

Verificare:

* permessi dei file;
* gruppo `wazuh`;
* path monitorato da Wazuh;
* uso di `copytruncate`;
* eventuali errori nei log Wazuh.

### Zeek continua a scrivere nel vecchio file

Verificare che sia presente:

```conf
copytruncate
```

## Cosa non caricare nella repository

Non caricare:

* log reali completi;
* log compressi `.gz`;
* PCAP;
* payload;
* malware;
* dati sensibili;
* credenziali;
* token.

Questa directory deve contenere solo configurazioni e documentazione.

## Best practice

* mantenere esplicito il percorso `/var/log/zeek-custom/*.log`;
* verificare la configurazione con `logrotate -d`;
* controllare permessi e gruppo dopo la rotazione;
* verificare che Wazuh continui a leggere i log;
* aggiornare questa configurazione se cambiano percorso o nome dei log custom;
* non versionare mai i log ruotati.
