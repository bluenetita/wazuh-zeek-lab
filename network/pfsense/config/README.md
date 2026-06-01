# pfSense Configuration Files

Questa directory contiene eventuali configurazioni pfSense esportate e sanificate.

## Obiettivo

L'obiettivo di questa directory è conservare una versione documentale e sicura della configurazione pfSense utilizzata nel laboratorio.

Le configurazioni possono essere utili per:

* ricostruire il setup;
* documentare interfacce e gateway;
* documentare regole firewall;
* documentare configurazioni NAT;
* confrontare modifiche nel tempo;
* rendere il laboratorio più riproducibile.

## File previsti

| File                   | Descrizione                                        |
| ---------------------- | -------------------------------------------------- |
| `README.md`            | Questo file                                        |
| `config-sanitized.xml` | Export pfSense sanificato                          |
| `config-example.xml`   | Esempio ridotto o generico                         |
| `config-notes.md`      | Note sulle modifiche applicate alla configurazione |

## File da non caricare

Non caricare mai nella repository:

* `config.xml` originale esportato da pfSense;
* backup completi non controllati;
* configurazioni contenenti password;
* configurazioni contenenti hash password;
* configurazioni contenenti private key;
* configurazioni contenenti certificati reali;
* configurazioni VPN con segreti;
* configurazioni con token;
* configurazioni con IP pubblici sensibili;
* configurazioni con hostname o dati personali non necessari.

## Export della configurazione

La configurazione pfSense può essere esportata dalla GUI:

```text
Diagnostics > Backup & Restore > Backup & Restore
```

Il file esportato è normalmente un file XML.

Il file originale esportato deve essere trattato come sensibile.

## Workflow consigliato

1. esportare la configurazione da pfSense;
2. salvare il file originale fuori dalla repository;
3. creare una copia da sanificare;
4. rimuovere o sostituire dati sensibili;
5. salvare la copia come `config-sanitized.xml`;
6. controllare il file con `grep`;
7. verificare il diff Git;
8. fare commit solo della versione sanificata.

Esempio:

```bash
cp config.xml network/pfsense/config/config-sanitized.xml
nano network/pfsense/config/config-sanitized.xml
```

## Elementi da sanificare

Prima del commit, controllare e sostituire almeno i seguenti elementi.

| Elemento XML                        | Azione consigliata         |
| ----------------------------------- | -------------------------- |
| `<bcrypt-hash>`                     | Sostituire con `REDACTED`  |
| `<password>`                        | Sostituire con `REDACTED`  |
| `<descr>` contenente dati sensibili | Rimuovere o generalizzare  |
| `<crt>`                             | Sostituire con `REDACTED`  |
| `<prv>`                             | Sostituire con `REDACTED`  |
| sezioni OpenVPN                     | Rimuovere o sanificare     |
| utenti reali                        | Sostituire con placeholder |
| IP pubblici                         | Sostituire con placeholder |
| hostname personali                  | Sostituire con placeholder |

## Esempio di sanificazione

Originale:

```xml
<bcrypt-hash>$2b$10$EXAMPLE_HASH_VALUE</bcrypt-hash>
```

Sanificato:

```xml
<bcrypt-hash>REDACTED</bcrypt-hash>
```

Originale:

```xml
<crt>BASE64_CERTIFICATE_CONTENT</crt>
```

Sanificato:

```xml
<crt>REDACTED</crt>
```

Originale:

```xml
<prv>BASE64_PRIVATE_KEY_CONTENT</prv>
```

Sanificato:

```xml
<prv>REDACTED</prv>
```

## Placeholder consigliati

Usare placeholder chiari e coerenti:

```text
REDACTED
PFSENSE_WAN_IP
PFSENSE_LAN_IP
WAN_GATEWAY
LAN_GATEWAY
ROUTEROS_IP
ATTACKER_IP
VICTIM_IP
CLIENT_NET
SERVER_NET
MONITORING_NET
INTERNAL_NET
EXTERNAL_NET
```

## Controllo rapido

Prima di fare commit, eseguire dalla root della repository:

```bash
grep -RniE "bcrypt|password|passwd|secret|key|private|cert|crt|prv|token|openvpn" network/pfsense/config/
```

Se il comando mostra ancora valori reali sensibili, non fare commit.

## Controllo Git

Prima del commit:

```bash
git diff network/pfsense/config/
```

Verificare che nel diff non compaiano:

* hash password reali;
* certificati reali;
* private key;
* token;
* segreti;
* dati personali;
* configurazioni non sanificate.

## Regole `.gitignore` consigliate

Nel file `.gitignore` della repository è consigliabile aggiungere:

```gitignore
# pfSense raw exports
network/pfsense/config/config.xml
network/pfsense/config/*raw*
network/pfsense/config/*backup*
network/pfsense/config/*original*
network/pfsense/config/*.bak

# Allow sanitized examples
!network/pfsense/config/config-sanitized.xml
!network/pfsense/config/config-example.xml
```

## Configurazione attualmente documentata

Dal file di configurazione analizzato, gli elementi documentabili in Markdown sono:

| Elemento        | Valore                             |
| --------------- | ---------------------------------- |
| WAN interface   | `vtnet0`                           |
| WAN IP          | `10.2.0.254/24`                    |
| WAN gateway     | `10.2.0.1`                         |
| LAN interface   | `vtnet1`                           |
| LAN IP          | `10.4.0.253/24`                    |
| Outbound NAT    | Automatic                          |
| SSH             | Enabled                            |
| Firewall rule 1 | Default allow LAN to any rule      |
| Firewall rule 2 | Default allow LAN IPv6 to any rule |

Questi valori possono essere documentati nei file:

```text
network/pfsense/interfaces.md
network/pfsense/firewall-rules.md
network/pfsense/nat.md
```

## Nota importante

La versione sanificata della configurazione serve solo a documentare il laboratorio.

Non deve contenere informazioni riutilizzabili per accedere al sistema o compromettere l'ambiente.
