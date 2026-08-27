# ServerDB SQL Schema

Questa directory contiene lo schema SQL sanificato del database PostgreSQL utilizzato nella VM `ServerDB`.

## Obiettivo

Lo scopo di questa directory è documentare la struttura del database usato nel laboratorio, senza esporre dati reali o informazioni sensibili.

Il database viene usato per simulare un servizio interno aziendale e può generare traffico client-server osservabile da Zeek e, se configurato, eventi host-based osservabili da Wazuh.

## File presenti

| File                 | Descrizione                                       |
| -------------------- | ------------------------------------------------- |
| `README.md`          | Questo file                                       |
| `schema-example.sql` | Schema SQL sanificato del database di laboratorio |

## Database documentato

Il database di test contiene due tabelle principali:

| Tabella          | Descrizione                              |
| ---------------- | ---------------------------------------- |
| `utenti`         | Tabella demo per utenti applicativi      |
| `dati_sensibili` | Tabella demo per dati sensibili simulati |

## Tabelle

### utenti

La tabella `utenti` rappresenta utenti demo dell'applicazione.

Campi principali:

| Campo           | Descrizione                              |
| --------------- | ---------------------------------------- |
| `id`            | Identificativo univoco                   |
| `username`      | Nome utente demo                         |
| `password_hash` | Placeholder per password/hash sanificato |
| `email`         | Email demo                               |
| `ruolo`         | Ruolo applicativo                        |

### dati_sensibili

La tabella `dati_sensibili` rappresenta dati sensibili simulati collegati agli utenti.

Campi principali:

| Campo                 | Descrizione                           |
| --------------------- | ------------------------------------- |
| `id`                  | Identificativo univoco                |
| `user_id`             | Riferimento alla tabella `utenti`     |
| `numero_carta_masked` | Numero carta mascherato o placeholder |
| `cvv_masked`          | CVV mascherato o placeholder          |
| `iban_masked`         | IBAN mascherato o placeholder         |

## Relazione tra le tabelle

La tabella `dati_sensibili` contiene una foreign key verso `utenti`.

Relazione logica:

```text
utenti.id
   |
   v
dati_sensibili.user_id
```

Query di verifica:

```sql
SELECT u.username, d.numero_carta_masked, d.cvv_masked
FROM utenti u
JOIN dati_sensibili d ON u.id = d.user_id;
```

## Sanificazione

Il file `schema-example.sql` deve contenere solo dati sintetici o placeholder.

Non inserire:

* password reali;
* password in chiaro;
* hash reali;
* numeri di carta reali;
* CVV reali;
* IBAN reali;
* dati personali;
* dump completi;
* backup reali;
* stringhe di connessione reali.

## Placeholder consigliati

Usare placeholder come:

```text
HASH_REDACTED
CARD_REDACTED_0001
CARD_REDACTED_0002
CARD_REDACTED_0003
IBAN_REDACTED_0001
IBAN_REDACTED_0002
IBAN_REDACTED_0003
CLIENT_IP
SERVER_DB_IP
```

## Relazione con Zeek

Zeek può osservare il traffico verso il server PostgreSQL se attraversa il punto di mirroring configurato su Open vSwitch.

Evidenze possibili:

| Log Zeek   | Evidenza                     |
| ---------- | ---------------------------- |
| `conn.log` | Connessione verso `ServerDB` |
| `conn.log` | Porta `5432/tcp`             |
| `conn.log` | Durata della connessione     |
| `conn.log` | Byte trasferiti              |

## Relazione con Wazuh

Se l'agent Wazuh è installato su `ServerDB`, può osservare:

* modifiche ai file di configurazione;
* modifiche allo schema o agli script SQL, se monitorati;
* eventi di autenticazione;
* log PostgreSQL, se configurati;
* eventi File Integrity Monitoring.

## Come generare lo schema

Per stampare a schermo solo lo schema del database:

```bash
sudo -u postgres pg_dump --schema-only NOME_DATABASE
```

Esempio:

```bash
sudo -u postgres pg_dump --schema-only aziendadb
```

Per salvare direttamente nel file:

```bash
sudo -u postgres pg_dump --schema-only aziendadb > infrastructure/server-db/sql/schema-example.sql
```

Prima del commit, controllare sempre che non ci siano dati sensibili.

## Controlli prima del commit

Eseguire:

```bash
grep -RniE "password|admin123|user1password|user2password|cvv|iban|11112222|55556666|99990000|secret|token|key|private" infrastructure/server-db/sql/
```

Controllare anche il diff:

```bash
git diff infrastructure/server-db/sql/
```

## Cosa non caricare

Non caricare in questa directory:

* dump completi con dati;
* backup database;
* file `.dump`;
* file `.backup`;
* export contenenti dati reali;
* credenziali;
* dati personali;
* numeri di carte o IBAN reali;
* log completi PostgreSQL.

## Best practice

* documentare solo la struttura del database;
* usare dati demo chiaramente fittizi;
* mascherare sempre dati sensibili;
* evitare password in chiaro;
* non caricare dump reali;
* aggiornare `schema-example.sql` se cambia la struttura del database;
* mantenere il database documentato coerente con gli scenari del laboratorio.
