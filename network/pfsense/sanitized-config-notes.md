# Sanitized pfSense Configuration Notes

Questo documento descrive come sanificare un export della configurazione pfSense prima di salvarlo nella repository.

## Obiettivo

L'obiettivo è conservare una versione documentale della configurazione pfSense senza esporre dati sensibili.

La configurazione sanificata può essere utile per:

* documentare interfacce;
* documentare gateway;
* documentare regole firewall;
* documentare NAT;
* confrontare modifiche nel tempo;
* rendere il laboratorio più riproducibile.

## Regola principale

Non caricare mai su GitHub il file `config.xml` originale esportato da pfSense.

Il file originale può contenere:

* hash password;
* utenti;
* certificati;
* chiavi private;
* configurazioni VPN;
* token;
* hostname;
* IP;
* gateway;
* informazioni interne.

## Export configurazione

La configurazione pfSense può essere esportata dalla GUI:

```text
Diagnostics > Backup & Restore > Backup & Restore
```

Il file esportato è solitamente chiamato:

```text
config.xml
```

Questo file deve essere trattato come sensibile.

## Workflow consigliato

1. esportare `config.xml` da pfSense;
2. salvare l'originale fuori dalla repository;
3. creare una copia da sanificare;
4. rinominare la copia in `config-sanitized.xml`;
5. rimuovere o sostituire i dati sensibili;
6. controllare il file con `grep`;
7. verificare il diff Git;
8. fare commit solo della versione sanificata.

Esempio:

```bash
cp config.xml network/pfsense/config/config-sanitized.xml
nano network/pfsense/config/config-sanitized.xml
```

## Elementi da sanificare

| Elemento        | Rischio               | Azione consigliata                                |
| --------------- | --------------------- | ------------------------------------------------- |
| `<bcrypt-hash>` | Hash password utente  | Sostituire con `REDACTED`                         |
| `<password>`    | Password o segreti    | Sostituire con `REDACTED`                         |
| `<user>`        | Utenti reali          | Mantenere solo se generico, altrimenti sanificare |
| `<crt>`         | Certificato           | Sostituire con `REDACTED`                         |
| `<prv>`         | Private key           | Sostituire con `REDACTED`                         |
| `<openvpn>`     | Possibili segreti VPN | Rimuovere o sanificare                            |
| `<ipsec>`       | Possibili segreti VPN | Rimuovere o sanificare                            |
| `<dnsserver>`   | Informazioni di rete  | Sanificare se necessario                          |
| `<gateway>`     | Informazioni di rete  | Sanificare se necessario                          |
| `<hostname>`    | Hostname del sistema  | Sanificare se contiene dati personali             |
| `<domain>`      | Dominio locale        | Sanificare se necessario                          |
| `<descr>`       | Commenti descrittivi  | Rimuovere dati sensibili                          |

## Esempi di sanificazione

### Hash password

Originale:

```xml
<bcrypt-hash>$2b$10$EXAMPLE_HASH_VALUE</bcrypt-hash>
```

Sanificato:

```xml
<bcrypt-hash>REDACTED</bcrypt-hash>
```

### Certificato

Originale:

```xml
<crt>BASE64_CERTIFICATE_CONTENT</crt>
```

Sanificato:

```xml
<crt>REDACTED</crt>
```

### Private key

Originale:

```xml
<prv>BASE64_PRIVATE_KEY_CONTENT</prv>
```

Sanificato:

```xml
<prv>REDACTED</prv>
```

### Indirizzi IP

Originale:

```xml
<ipaddr>10.2.0.254</ipaddr>
```

Sanificato, se si vuole nascondere la rete:

```xml
<ipaddr>PFSENSE_WAN_IP</ipaddr>
```

Originale:

```xml
<gateway>10.2.0.1</gateway>
```

Sanificato:

```xml
<gateway>WAN_GATEWAY</gateway>
```

## Placeholder consigliati

Usare placeholder chiari e coerenti.

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

## Cosa può rimanere nel file

In una versione sanificata possono rimanere informazioni utili e non sensibili, ad esempio:

* nomi logici delle interfacce;
* struttura delle regole firewall;
* modalità NAT;
* nomi generici di gateway;
* topologia logica;
* configurazioni non riutilizzabili per accedere al sistema.

Esempio:

```xml
<nat>
  <outbound>
    <mode>automatic</mode>
  </outbound>
</nat>
```

## Configurazione attualmente ricavata

Dall'export analizzato sono stati ricavati questi elementi documentabili:

| Elemento             | Valore                        |
| -------------------- | ----------------------------- |
| WAN interface        | `vtnet0`                      |
| WAN IP               | `10.2.0.254/24`               |
| WAN gateway          | `10.2.0.1`                    |
| LAN interface        | `vtnet1`                      |
| LAN IP               | `10.4.0.253/24`               |
| LAN gateway          | `10.3.0.1`                    |
| Outbound NAT         | `automatic`                   |
| SSH                  | `enabled`                     |
| Regola firewall IPv4 | Default allow LAN to any      |
| Regola firewall IPv6 | Default allow LAN IPv6 to any |

Queste informazioni possono essere documentate nei file Markdown dedicati:

```text
network/pfsense/README.md
network/pfsense/interfaces.md
network/pfsense/firewall-rules.md
network/pfsense/nat.md
```

## Controllo con grep

Prima di fare commit, eseguire dalla root della repository:

```bash
grep -RniE "bcrypt|password|passwd|secret|key|private|cert|crt|prv|token|openvpn|ipsec" network/pfsense/
```

Se compaiono ancora dati sensibili reali, non fare commit.

## Controllo Git

Prima del commit:

```bash
git diff network/pfsense/
```

Verificare che nel diff non compaiano:

* hash password reali;
* chiavi private;
* certificati reali;
* token;
* segreti VPN;
* dati personali;
* export originali non controllati.

## Regole `.gitignore` consigliate

Nel file `.gitignore` della root aggiungere:

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

## Nome file consigliato

Usare nomi chiari:

```text
config-sanitized.xml
config-example.xml
config-notes.md
```

Evitare nomi ambigui come:

```text
config.xml
backup.xml
pfsense-full.xml
original.xml
```

## Note operative

La configurazione sanificata serve solo a documentare il laboratorio.

Non deve contenere informazioni riutilizzabili per accedere al sistema o compromettere l'ambiente.

Se non si è sicuri che il file sia correttamente sanificato, è preferibile non caricarlo e documentare la configurazione manualmente nei file Markdown.
