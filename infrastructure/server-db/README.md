# ServerDB

Questa directory contiene la documentazione relativa alla VM database server utilizzata nel laboratorio.

## Ruolo nel laboratorio

`ServerDB` rappresenta un server database interno dell'infrastruttura aziendale simulata.

Il suo ruolo è simulare un servizio server interno, raggiungibile dai client o da altri sistemi autorizzati, e generare traffico/eventi utili per l'analisi con Zeek e Wazuh.

## Posizione nella rete

| Campo               | Valore           |
| ------------------- | ---------------- |
| Nome VM             | `ServerDB`       |
| Tipo                | Database server  |
| Servizio principale | PostgreSQL       |
| VLAN                | VLAN 30 - Server |
| Subnet              | `10.3.30.0/24`   |
| Gateway             | `10.3.30.1`      |
| Gateway device      | RouterOS         |

## Ruolo della VLAN

La VM si trova nella VLAN 30, dedicata ai server interni.

Questa VLAN contiene sistemi che espongono servizi o che possono essere usati come target negli scenari controllati.

## Servizi principali

Il servizio principale previsto per questa VM è PostgreSQL.

| Servizio   | Porta default | Scopo            |
| ---------- | ------------: | ---------------- |
| PostgreSQL |    `5432/tcp` | Database interno |

## Connettività

### Client verso ServerDB

```text
ClientVM / WindowsVM
   |
   v
VLAN 20
   |
   v
RouterOS
   |
   v
VLAN 30
   |
   v
ServerDB
```

### ServerDB verso rete esterna

```text
ServerDB
   |
   v
VLAN 30
   |
   v
RouterOS
   |
   v
pfSense
   |
   v
Rete esterna simulata
```

## Relazione con Zeek

Zeek può osservare il traffico diretto verso `ServerDB` se il traffico attraversa il punto di mirroring configurato su Open vSwitch.

Evidenze possibili nei log Zeek:

| Log Zeek    | Evidenza                                     |
| ----------- | -------------------------------------------- |
| `conn.log`  | Connessioni verso PostgreSQL o altri servizi |
| `dns.log`   | Eventuali query DNS generate dal server      |
| `tls.log`   | Metadati TLS, se usati                       |
| `weird.log` | Eventuali anomalie di traffico               |

Nel caso di traffico PostgreSQL, Zeek può osservare principalmente metadati di connessione, come IP sorgente/destinazione, porta e durata.

## Relazione con Wazuh

Se l'agent Wazuh è installato su `ServerDB`, il sistema può produrre eventi host-based.

Esempi:

* autenticazioni;
* log di sistema;
* modifiche al filesystem;
* eventi File Integrity Monitoring;
* modifiche ai file di configurazione PostgreSQL;
* log applicativi PostgreSQL;
* eventi relativi a servizi;
* inventory di sistema.

## File PostgreSQL rilevanti

A seconda della distribuzione e della versione, i file PostgreSQL possono trovarsi in percorsi simili a:

```text
/etc/postgresql/<version>/main/postgresql.conf
/etc/postgresql/<version>/main/pg_hba.conf
/var/log/postgresql/
```

Se questi file vengono documentati nella repo, devono essere sanificati.

## Configurazioni PostgreSQL da documentare

È possibile documentare:

* porta di ascolto;
* indirizzi autorizzati;
* regole `pg_hba.conf`;
* eventuali database di test;
* utenti fittizi;
* impostazioni di logging;
* configurazione Wazuh agent se modificata;
* note di sicurezza.

Non caricare dump reali o credenziali.

## Scenari collegati

`ServerDB` può essere coinvolto in diversi scenari:

| Scenario                | Ruolo della VM                                                          |
| ----------------------- | ----------------------------------------------------------------------- |
| Test client-server      | Server interno raggiunto dai client                                     |
| SSH Brute Force         | Possibile target se SSH è attivo                                        |
| Data Exfiltration       | Possibile origine di dati da esfiltrare                                 |
| Privilege Escalation    | Possibile attività locale monitorata da Wazuh                           |
| Post-exploitation       | Possibile target dopo compromissione di un host                         |
| Correlazione Zeek-Wazuh | Traffico database osservabile da Zeek, eventi host osservabili da Wazuh |

## Verifiche utili

Verificare configurazione IP:

```bash
ip addr
ip route
```

Verificare raggiungibilità del gateway:

```bash
ping 10.3.30.1
```

Verificare stato PostgreSQL:

```bash
sudo systemctl status postgresql
```

Verificare porte in ascolto:

```bash
ss -tulpn
```

Verificare log PostgreSQL:

```bash
sudo ls -lh /var/log/postgresql/
```

Verificare stato agent Wazuh:

```bash
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
```

## Configurazioni da versionare

È possibile versionare in questa directory:

* configurazioni PostgreSQL sanificate;
* note di setup;
* configurazioni Wazuh agent se modificate;
* esempi di log sanificati;
* script SQL di esempio senza dati sensibili;
* schema database fittizio.

## Configurazioni da non versionare

Non caricare:

* password database;
* stringhe di connessione reali;
* dump database reali;
* dati personali;
* token;
* chiavi private;
* certificati privati;
* log completi;
* alert completi;
* file generati durante scenari offensivi;
* malware o payload.

## Note operative

Questa VM rappresenta un server interno.

Se PostgreSQL è usato solo come servizio di laboratorio, documentare configurazioni e test senza caricare dati reali.

Se in futuro vengono aggiunte configurazioni specifiche, creare sotto-directory dedicate, ad esempio:

```text
configs/
logs-samples/
sql/
```

## Best practice

* mantenere i dati del database fuori dalla repository;
* versionare solo configurazioni sanificate;
* separare configurazioni da evidenze;
* documentare eventuali modifiche a PostgreSQL;
* collegare la VM agli scenari in cui viene usata;
* aggiornare questa documentazione se cambiano IP, VLAN, servizi o ruolo della VM.
