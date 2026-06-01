# Wazuh Decoders

Questa directory contiene i decoder XML custom utilizzati da Wazuh per interpretare i log Zeek standard e custom.

## Obiettivo

I decoder servono a estrarre campi strutturati dai log ricevuti da Wazuh.

Nel laboratorio, l'agent Wazuh installato sulla VM Zeek raccoglie:

* log Zeek standard da `/opt/zeek/logs/current/*.log`;
* log custom Zeek da `/var/log/zeek-custom/`.

I decoder presenti in questa directory permettono al Wazuh Manager di interpretare questi eventi e renderli utilizzabili dalle regole custom.

## File presenti

| File                      | Descrizione                   |
| ------------------------- | ----------------------------- |
| `README.md`               | Questo file                   |
| `zeek_decoders.xml`       | Decoder per log Zeek standard |
| `zeek_decoder_custom.xml` | Decoder per log Zeek custom   |

## zeek_decoders.xml

Il file `zeek_decoders.xml` contiene decoder per log Zeek standard.

Esempi di campi estratti:

| Campo               | Descrizione                     |
| ------------------- | ------------------------------- |
| `timestamp`         | Timestamp evento                |
| `uid`               | Identificatore connessione Zeek |
| `srcip`             | IP sorgente                     |
| `srcport`           | Porta sorgente                  |
| `dstip`             | IP destinazione                 |
| `dstport`           | Porta destinazione              |
| `protocol`          | Protocollo                      |
| `dnsquery`          | Query DNS                       |
| `dns_response_code` | Codice risposta DNS             |
| `connection_state`  | Stato connessione               |
| `ssl_version`       | Versione SSL/TLS                |
| `ssl_cipher`        | Cipher TLS                      |
| `ssl_server_name`   | Server Name Indication          |

Questi decoder sono utili per interpretare log come:

* `conn.log`;
* `dns.log`;
* `ssl.log`;
* `tls.log`;
* `software.log`.

## zeek_decoder_custom.xml

Il file `zeek_decoder_custom.xml` contiene decoder per log custom generati dagli script Zeek del laboratorio.

Esempi di campi estratti:

| Campo              | Descrizione                |
| ------------------ | -------------------------- |
| `event_type`       | Tipo evento custom         |
| `source_ip`        | IP sorgente                |
| `destination_ip`   | IP destinazione            |
| `destination_port` | Porta destinazione         |
| `file_name`        | Nome file osservato        |
| `mime_type`        | MIME type                  |
| `total_bytes`      | Dimensione trasferimento   |
| `sha1`             | Hash SHA1                  |
| `sha256`           | Hash SHA256                |
| `note`             | Nota o descrizione evento  |
| `uid`              | Identificatore connessione |
| `payload_type`     | Tipo payload o weird name  |
| `duration`         | Durata connessione         |
| `origin_bytes`     | Byte inviati dall'origine  |
| `response_bytes`   | Byte inviati dal responder |
| `origin_packets`   | Pacchetti origine          |
| `response_packets` | Pacchetti risposta         |

Questi decoder sono collegati a log custom come:

* `possible_malware.log`;
* `reverse_shell_live.log`;
* `reverse_shell_final.log`;
* `reverse_shell_movement.log`.

## Flusso di integrazione

```text
Zeek logs
   |
   v
Wazuh Agent su ZeekVM
   |
   v
Wazuh Manager
   |
   v
Decoders
   |
   v
Rules
   |
   v
Alerts
```

## Percorso di installazione

Sul Wazuh Manager, i decoder custom possono essere copiati in:

```text
/var/ossec/etc/decoders/
```

Esempio:

```bash
sudo cp blue-team/wazuh/decoders/zeek_decoders.xml /var/ossec/etc/decoders/
sudo cp blue-team/wazuh/decoders/zeek_decoder_custom.xml /var/ossec/etc/decoders/
```

Dopo la copia, riavviare il manager:

```bash
sudo systemctl restart wazuh-manager
```

## Verifiche

Controllare errori nel manager:

```bash
sudo grep -iE "error|decoder" /var/ossec/logs/ossec.log
```

Controllare stato del manager:

```bash
sudo systemctl status wazuh-manager
```

## Note operative

* Dopo ogni modifica ai decoder, riavviare il Wazuh Manager.
* Verificare sempre i log di Wazuh dopo il riavvio.
* I decoder devono essere coerenti con il formato JSON dei log Zeek.
* Se cambia il formato dei log custom Zeek, aggiornare anche `zeek_decoder_custom.xml`.
* Se cambiano i nomi dei campi generati da Zeek, aggiornare anche le regole in `blue-team/wazuh/rules/`.

## Cosa non caricare

Non caricare:

* log completi reali;
* alert completi;
* credenziali;
* token;
* chiavi private;
* dati personali.

Questa directory deve contenere solo decoder e documentazione.

## Best practice

* mantenere separati decoder standard e custom;
* usare nomi file descrittivi;
* testare un decoder alla volta;
* documentare quali log vengono interpretati;
* mantenere allineati decoder, rules e script Zeek.
