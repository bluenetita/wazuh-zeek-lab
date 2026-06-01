# Zeek Evidence - Reverse Shell

Questa directory contiene evidenze sanificate prodotte da Zeek durante lo scenario Reverse Shell.

## Obiettivo

L'obiettivo è documentare le evidenze network-based osservate da Zeek durante lo scenario Reverse Shell tra Client Linux e AttackerVM.

Le evidenze devono mostrare cosa è stato osservato a livello di rete, senza includere PCAP completi, payload, exploit, malware, credenziali o log grezzi completi.

## Scenario di riferimento

| Campo               | Valore                  |
| ------------------- | ----------------------- |
| Scenario            | Reverse Shell           |
| Stato               | Completato              |
| Target              | Client Linux / ClientVM |
| Macchina attaccante | AttackerVM / Kali Linux |
| Fonte principale    | Zeek                    |
| Tipo evidenza       | Network-based           |

## Ruolo di Zeek

Zeek osserva il traffico duplicato tramite mirror Open vSwitch configurato su Proxmox.

Il flusso è:

```text
Traffico Client Linux / AttackerVM
   |
   v
vmbr2 / Open vSwitch mirror
   |
   v
VLAN 999
   |
   v
ZeekVM
   |
   v
Zeek logs
```

## Log Zeek rilevanti

Durante lo scenario Reverse Shell, Zeek può produrre evidenze nei log standard e nei log custom.

| Log                          | Descrizione                                         |
| ---------------------------- | --------------------------------------------------- |
| `conn.log`                   | Connessioni TCP tra Client Linux e AttackerVM       |
| `http.log`                   | Eventuale traffico HTTP o download controllato      |
| `notice.log`                 | Eventuali notice generate da Zeek                   |
| `weird.log`                  | Eventuali anomalie di protocollo                    |
| `possible_malware.log`       | Possibile download o trasferimento sospetto         |
| `reverse_shell_live.log`     | Possibile reverse shell in corso                    |
| `reverse_shell_movement.log` | Traffico associato alla connessione                 |
| `reverse_shell_final.log`    | Chiusura o classificazione finale della connessione |

## Percorsi dei log

Log standard Zeek:

```text
/opt/zeek/logs/current/
```

Log custom Zeek:

```text
/var/log/zeek-custom/
```

## Tipi di evidenze ammesse

È possibile includere esempi piccoli e sanificati come:

```text
zeek-conn-reverse-shell-sample.log
zeek-http-download-sample.log
zeek-custom-possible-malware-sample.log
zeek-custom-reverse-shell-live-sample.log
zeek-custom-reverse-shell-movement-sample.log
zeek-custom-reverse-shell-final-sample.log
notes.md
```

## Tipi di evidenze non ammesse

Non caricare:

* PCAP completi;
* log Zeek completi;
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
* dati personali.

## Placeholder consigliati

Prima di inserire una evidenza, sostituire i dati reali con placeholder.

| Valore reale       | Placeholder          |
| ------------------ | -------------------- |
| IP AttackerVM      | `ATTACKER_IP`        |
| IP Client Linux    | `CLIENT_IP`          |
| IP ZeekVM          | `ZEEK_IP`            |
| Timestamp reale    | `TIMESTAMP`          |
| UID Zeek           | `UID`                |
| Porta listener     | `SCENARIO_PORT`      |
| Hash reale         | `HASH_REDACTED`      |
| Nome file sospetto | `FILE_NAME_REDACTED` |
| Path sensibile     | `PATH_REDACTED`      |

## Esempio di evidenza Zeek sanificata

Esempio ridotto di evento custom collegato a reverse shell:

```json
{
  "ts": "TIMESTAMP",
  "uid": "UID",
  "event_type": "reverse_shell_live",
  "src_ip": "CLIENT_IP",
  "dest_ip": "ATTACKER_IP",
  "dest_port": "SCENARIO_PORT",
  "weird_name": "PAYLOAD_TYPE_REDACTED",
  "note": "Possible reverse shell activity detected"
}
```

Esempio ridotto di connessione:

```text
TIMESTAMP UID CLIENT_IP CLIENT_PORT ATTACKER_IP SCENARIO_PORT tcp DURATION ORIG_BYTES RESP_BYTES
```

## Come documentare una evidenza

Ogni evidenza dovrebbe indicare:

* fonte;
* log di origine;
* scenario;
* host coinvolti;
* cosa dimostra;
* dati sanificati;
* eventuale collegamento con alert Wazuh.

Esempio:

```text
Fonte: Zeek
Log origine: reverse_shell_live.log
Scenario: Reverse Shell
Host coinvolti: Client Linux, AttackerVM
Descrizione: evento custom generato per possibile reverse shell live
Dati sanificati: IP, timestamp, UID, porta
```

## Relazione con Wazuh

I log custom Zeek vengono raccolti dall'agent Wazuh installato su ZeekVM.

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

Le evidenze Wazuh correlate sono documentate in:

```text
evidence/reverse-shell/wazuh/
```

## Relazione con decoder e rules

I log custom Zeek vengono interpretati da Wazuh tramite decoder e regole custom.

Directory correlate:

```text
blue-team/wazuh/decoders/
blue-team/wazuh/rules/
```

File rilevanti:

```text
zeek_decoder_custom.xml
002_zeek_rules_custom.xml
003_zeek_correlations.xml
```

## Verifiche utili

Sulla VM Zeek, verificare i log custom:

```bash
ls -lh /var/log/zeek-custom/
```

Seguire un log custom:

```bash
tail -f /var/log/zeek-custom/reverse_shell_live.log
```

Verificare log standard Zeek:

```bash
ls -lh /opt/zeek/logs/current/
```

Verificare traffico sull'interfaccia di monitoring:

```bash
sudo tcpdump -i ens19 -n
sudo tcpdump -i ens19.999 -n
```

Verificare stato Zeek:

```bash
sudo /opt/zeek/bin/zeekctl status
```

## Controlli prima del commit

Prima di fare commit, eseguire:

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|payload|exploit" evidence/reverse-shell/zeek/
```

Controllare anche il diff:

```bash
git diff evidence/reverse-shell/zeek/
```

## Note operative

Questa directory deve contenere solo evidenze utili alla validazione dello scenario Reverse Shell.

Non deve contenere materiale offensivo, payload o log completi.

## Best practice

* mantenere i log piccoli e sanificati;
* includere solo eventi utili alla validazione;
* non caricare PCAP completi;
* indicare sempre il log di origine;
* usare placeholder coerenti;
* collegare le evidenze Zeek agli alert Wazuh quando possibile;
* documentare cosa dimostra ogni evidenza.
