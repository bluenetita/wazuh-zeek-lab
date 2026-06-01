# Zeek Log Samples

Questa directory contiene esempi sanificati di log generati da Zeek durante gli scenari del laboratorio.

## Obiettivo

Gli esempi di log servono a documentare il tipo di evidenze prodotte da Zeek.

Questi file aiutano a capire:

* quali eventi sono osservabili a livello rete;
* quali campi sono utili durante l'analisi;
* come si presenta un log Zeek;
* quali evidenze possono essere correlate con Wazuh;
* quali scenari generano determinati tipi di log.

## Regola principale

In questa directory devono essere caricati solo esempi ridotti e sanificati.

Non caricare log completi reali.

Non caricare PCAP.

Non caricare file contenenti dati sensibili.

## File previsti

| File                | Descrizione                                  |
| ------------------- | -------------------------------------------- |
| `conn.log`   | Esempio di connessione osservata da Zeek     |
| `dns.log`    | Esempio di query DNS                         |
| `http.log`   | Esempio di traffico HTTP                     |
| `notice.log` | Esempio di notice generata da Zeek           |
| `weird.log`  | Esempio di evento anomalo                    |
| `custom/`           | Esempi di log custom generati da script Zeek |

## Log standard Zeek

I log standard più utili nel laboratorio sono:

| Log          | Utilità                                |
| ------------ | -------------------------------------- |
| `conn.log`   | Analisi delle connessioni TCP/UDP/ICMP |
| `dns.log`    | Analisi delle richieste DNS            |
| `http.log`   | Analisi di traffico HTTP e download    |
| `tls.log`    | Analisi di metadati TLS                |
| `notice.log` | Eventi rilevanti generati da Zeek      |
| `weird.log`  | Eventi anomali o inattesi              |

## Log custom

Gli script custom possono generare log dedicati a scenari specifici.

Esempi previsti:

| Log custom                          | Descrizione                                           |
| ----------------------------------- | ----------------------------------------------------- |
| `possible-malware.log`       | Possibile download o trasferimento sospetto           |
| `reverse-shell-live.log`     | Connessione persistente compatibile con reverse shell |
| `reverse-shell-movement.log` | Pattern collegati ad attività sospetta                |
| `reverse-shell-final.log`    | Classificazione finale o evento aggregato             |

## Placeholder consigliati

Sostituire sempre valori reali con placeholder.

| Valore reale        | Placeholder         |
| ------------------- | ------------------- |
| IP macchina Kali    | `ATTACKER_IP`       |
| IP macchina vittima | `VICTIM_IP`         |
| IP client Linux     | `CLIENT_IP`         |
| IP server database  | `SERVER_DB_IP`      |
| IP Zeek             | `ZEEK_IP`           |
| IP Wazuh            | `WAZUH_IP`          |
| Porta listener      | `SCENARIO_PORT`     |
| Timestamp reale     | `TIMESTAMP`         |
| UID reale Zeek      | `UID`               |
| Hostname reale      | `HOSTNAME_REDACTED` |

## Cosa non caricare

Non caricare:

* log completi non filtrati;
* file `.pcap` o `.pcapng`;
* IP pubblici sensibili;
* hostname personali;
* credenziali;
* token;
* payload;
* malware;
* file scaricati durante gli scenari;
* dati personali;
* output troppo lunghi non necessari.

## Come creare un sample sicuro

Partire da un log reale e copiare solo poche righe rilevanti.

Esempio:

```bash
sudo tail -n 5 /opt/zeek/logs/current/conn.log
```

Poi creare un file sample:

```bash
nano blue-team/zeek/logs-samples/conn-sample.log
```

Sostituire i valori reali con placeholder.

Esempio:

```text
10.3.30.10 -> VICTIM_IP
10.2.0.10 -> ATTACKER_IP
1740000000.12345 -> TIMESTAMP
CAbCdEf123456 -> UID
```

## Esempio di log sanificato

Esempio di riga `conn.log` sanificata:

```text
TIMESTAMP	UID	VICTIM_IP	51514	ATTACKER_IP	4444	tcp	-	3600.000000	2048	1024	S1	T	F	0	ShADad	120	9000	100	7000
```

Questo esempio può rappresentare una connessione TCP persistente compatibile con uno scenario di reverse shell.

## Relazione con gli scenari

| Scenario          | Log Zeek utili                                 |
| ----------------- | ---------------------------------------------- |
| Reverse Shell     | `conn.log`, log custom reverse shell           |
| SSH Brute Force   | `conn.log`, eventuale `notice.log`             |
| ICMP Flood        | `conn.log`, eventuale `weird.log`              |
| MITM / Spoofing   | `dns.log`, `weird.log`, log custom             |
| Data Exfiltration | `conn.log`, `http.log`, `tls.log`              |
| Download Payload  | `http.log`, `conn.log`, `possible_malware.log` |

## Relazione con Wazuh

Gli esempi di log Zeek possono essere usati per:

* creare decoder Wazuh;
* testare regole custom;
* verificare la correlazione tra traffico di rete e eventi host;
* documentare scenari di attacco;
* mostrare quali campi vengono estratti.

Esempio di correlazione:

| Evidenza Zeek                                   | Evidenza Wazuh                               |
| ----------------------------------------------- | -------------------------------------------- |
| Connessione TCP persistente verso `ATTACKER_IP` | Alert host-based o evento FIM sulla VictimVM |
| Download HTTP da `ATTACKER_IP`                  | File creato o modificato sul filesystem      |
| Tentativi SSH ripetuti                          | Alert autenticazioni fallite                 |
| Traffico in uscita elevato                      | Accesso o compressione di file locali        |

## Controlli prima del commit

Prima di fare commit:

```bash
grep -RniE "password|passwd|secret|key|token|private|credential" blue-team/zeek/logs-samples/
```

Controllare anche manualmente il diff:

```bash
git diff blue-team/zeek/logs-samples/
```

## Best practice

* mantenere i sample piccoli;
* usare placeholder coerenti;
* includere solo righe utili;
* documentare a quale scenario si riferisce il sample;
* non caricare log grezzi completi;
* non caricare PCAP;
* non caricare payload;
* aggiornare i sample quando cambiano gli script custom.

## Note finali

Questa directory serve a documentare esempi di evidenze, non ad archiviare tutti i log del laboratorio.

I log reali completi devono rimanere fuori dalla repository.
