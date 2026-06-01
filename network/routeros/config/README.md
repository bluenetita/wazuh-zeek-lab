# RouterOS Configuration Files

Questa directory contiene le configurazioni RouterOS esportate e sanificate.

## Obiettivo

L'obiettivo di questa directory è conservare una versione sicura e documentale della configurazione RouterOS utilizzata nel laboratorio.

Le configurazioni possono essere utili per:

* ricostruire il setup;
* documentare interfacce;
* documentare VLAN;
* documentare indirizzi IP;
* documentare routing;
* documentare firewall e NAT;
* confrontare modifiche nel tempo;
* rendere il laboratorio più riproducibile.

## File previsti

| File                            | Descrizione                                 |
| ------------------------------- | ------------------------------------------- |
| `README.md`                     | Questo file                                 |
| `routeros-config-sanitized.rsc` | Configurazione RouterOS reale, sanificata   |
| `routeros-config-example.rsc`   | Configurazione RouterOS generica di esempio |

## Export della configurazione

Da terminale RouterOS:

```text
/export hide-sensitive
```

Per salvare l'export su file:

```text
/export hide-sensitive file=routeros-config
```

Il comando `hide-sensitive` rimuove molte informazioni sensibili, ma non sostituisce un controllo manuale.

Prima di caricare un export nella repository, controllare sempre il contenuto.

## Configurazione attualmente documentata

La configurazione RouterOS del laboratorio include:

| Area          | Configurazione                                |
| ------------- | --------------------------------------------- |
| WAN           | `ether1` verso pfSense                        |
| LAN           | `ether2` verso `vmbr2`                        |
| TEST          | `ether3` verso `vmbr4-test`                   |
| VLAN 10       | `vlan10` su `ether2`                          |
| VLAN 20       | `vlan20` su `ether2`                          |
| VLAN 30       | `vlan30` su `ether2`                          |
| Default route | Gateway pfSense `10.4.0.253`                  |
| VPN route     | `10.8.0.0/24` via `10.3.0.254`                |
| NAT           | Masquerade verso `ether1`                     |
| DHCP server   | Non configurato                               |
| DNS           | `1.1.1.1`, `8.8.8.8`                          |
| Firewall      | Allow-list su chain `forward` con drop finale |

## File `routeros-config-sanitized.rsc`

Questo file contiene la configurazione reale del laboratorio, ma ripulita da dati non necessari o sensibili.

Può includere:

* interfacce Ethernet;
* VLAN;
* indirizzi IP;
* DNS;
* firewall filter;
* NAT;
* rotte statiche.

Non deve includere:

* password;
* utenti;
* chiavi private;
* certificati;
* token;
* secret;
* configurazioni VPN sensibili;
* system-id;
* dati personali.

## File `routeros-config-example.rsc`

Questo file contiene un esempio generico, utile come template.

Deve usare placeholder invece di valori reali.

Esempi di placeholder:

```text
TRUNK_INTERFACE
PFSENSE_UPLINK_INTERFACE
ROUTEROS_WAN_IP
PFSENSE_INTERNAL_IP
VLAN10_GATEWAY
VLAN20_GATEWAY
VLAN30_GATEWAY
CLIENT_NET
SERVER_NET
MONITORING_NET
VPN_NET
REDACTED
```

## Sanificazione

Anche se `hide-sensitive` è attivo, controllare manualmente il file.

Elementi da verificare:

| Elemento              | Azione                     |
| --------------------- | -------------------------- |
| Password              | Rimuovere                  |
| Utenti reali          | Rimuovere o sanificare     |
| Certificati           | Rimuovere                  |
| Chiavi private        | Rimuovere                  |
| VPN secrets           | Rimuovere                  |
| Token                 | Rimuovere                  |
| System ID             | Rimuovere                  |
| IP pubblici sensibili | Sostituire con placeholder |
| Commenti sensibili    | Rimuovere o generalizzare  |

## Controllo rapido

Prima del commit, eseguire dalla root della repository:

```bash
grep -RniE "password|passwd|secret|key|private|cert|token|user|wireguard|ipsec|system id" network/routeros/config/
```

Se compaiono dati sensibili reali, non fare commit.

## Controllo Git

Prima del commit:

```bash
git diff network/routeros/config/
```

Verificare che nel diff non compaiano:

* password;
* chiavi;
* secret;
* token;
* certificati;
* system-id;
* export originali non controllati.

## Regole `.gitignore` consigliate

Nel file `.gitignore` della root è consigliabile aggiungere:

```gitignore
# RouterOS raw exports
network/routeros/config/*raw*
network/routeros/config/*backup*
network/routeros/config/*original*
network/routeros/config/*.backup
network/routeros/config/*.bak

# Allow sanitized configs
!network/routeros/config/routeros-config-sanitized.rsc
!network/routeros/config/routeros-config-example.rsc
```

## Workflow consigliato

1. esportare la configurazione con `/export hide-sensitive`;
2. copiare l'output in `routeros-config-sanitized.rsc`;
3. rimuovere righe non necessarie, come `system id`;
4. controllare eventuali dati sensibili;
5. verificare il diff Git;
6. fare commit solo della versione sanificata.

## Comandi utili

Esportare configurazione:

```text
/export hide-sensitive
```

Visualizzare interfacce:

```text
/interface print
```

Visualizzare VLAN:

```text
/interface vlan print detail
```

Visualizzare IP:

```text
/ip address print detail
```

Visualizzare rotte:

```text
/ip route print detail
```

Visualizzare firewall:

```text
/ip firewall filter print detail
```

Visualizzare NAT:

```text
/ip firewall nat print detail
```

## Note operative

La configurazione sanificata serve a documentare il laboratorio.

Non deve contenere informazioni riutilizzabili per accedere al sistema o compromettere l'ambiente.

Se non si è sicuri che il file sia completamente sicuro, è preferibile non caricarlo e documentare la configurazione nei file Markdown.
