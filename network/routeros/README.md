# RouterOS

Questa directory contiene la documentazione e le configurazioni sanificate relative a RouterOS.

RouterOS è utilizzato nel laboratorio come router inter-VLAN tra i segmenti interni dell'infrastruttura e come nodo di inoltro verso pfSense.

## Ruolo nel laboratorio

RouterOS gestisce la comunicazione tra:

* VLAN 10 - Monitoring;
* VLAN 20 - Client;
* VLAN 30 - Server;
* pfSense;
* rete esterna simulata tramite pfSense;
* rete VPN tramite Proxmox;
* eventuale rete di test separata.

Il suo compito principale è fornire routing tra le VLAN interne e inoltrare il traffico verso pfSense quando la destinazione si trova fuori dalla rete interna.

## Collegamenti logici

| Interfaccia | Ruolo                      | Collegamento | Rete           |
| ----------- | -------------------------- | ------------ | -------------- |
| `ether1`    | WAN / uplink verso pfSense | pfSense      | `10.4.0.0/24`  |
| `ether2`    | LAN / trunk VLAN interne   | `vmbr2`      | `10.3.0.0/16`  |
| `ether3`    | Rete test                  | `vmbr4-test` | `10.5.0.0/24`  |
| `vlan10`    | Gateway Monitoring         | VLAN 10      | `10.3.10.0/24` |
| `vlan20`    | Gateway Client             | VLAN 20      | `10.3.20.0/24` |
| `vlan30`    | Gateway Server             | VLAN 30      | `10.3.30.0/24` |

## Indirizzi principali

| Interfaccia | IP / Subnet     | Ruolo                   |
| ----------- | --------------- | ----------------------- |
| `ether1`    | `10.4.0.252/24` | WAN verso pfSense       |
| `ether2`    | `10.3.0.1/16`   | LAN gateway generale    |
| `vlan10`    | `10.3.10.1/24`  | Gateway VLAN Monitoring |
| `vlan20`    | `10.3.20.1/24`  | Gateway VLAN Client     |
| `vlan30`    | `10.3.30.1/24`  | Gateway VLAN Server     |
| `ether3`    | `10.5.0.1/24`   | Rete test               |

## VLAN gestite

Le VLAN interne sono configurate su `ether2`.

| VLAN | Nome interfaccia | Subnet         | Gateway     | Ruolo      |
| ---: | ---------------- | -------------- | ----------- | ---------- |
|   10 | `vlan10`         | `10.3.10.0/24` | `10.3.10.1` | Monitoring |
|   20 | `vlan20`         | `10.3.20.0/24` | `10.3.20.1` | Client     |
|   30 | `vlan30`         | `10.3.30.0/24` | `10.3.30.1` | Server     |

## Routing

RouterOS gestisce il routing tra le VLAN interne e inoltra il traffico verso pfSense.

### Default route

| Destinazione | Gateway      | Interfaccia | Descrizione           |
| ------------ | ------------ | ----------- | --------------------- |
| `0.0.0.0/0`  | `10.4.0.253` | `ether1`    | Route via WAN pfSense |

### Rotta VPN

| Destinazione  | Gateway      | Interfaccia | Descrizione     |
| ------------- | ------------ | ----------- | --------------- |
| `10.8.0.0/24` | `10.3.0.254` | `ether2`    | VPN via Proxmox |

## NAT

RouterOS applica una regola di masquerade verso `ether1`.

| Chain    | Azione       | Out interface | Descrizione       |
| -------- | ------------ | ------------- | ----------------- |
| `srcnat` | `masquerade` | `ether1`      | NAT LAN verso WAN |

Questa configurazione permette alle reti interne di uscire verso pfSense tramite `ether1`.

Nota importante: il masquerade può modificare l'IP sorgente visto da pfSense. Per questo motivo, nei log pfSense il traffico proveniente dalle VLAN potrebbe apparire come proveniente da RouterOS.

## Firewall

RouterOS applica regole firewall sulla chain `forward`.

La logica configurata è:

1. FastTrack per connessioni established/related;
2. accettazione connessioni established/related;
3. traffico consentito tra VLAN 10, VLAN 20 e VLAN 30;
4. traffico consentito dalle VLAN verso WAN;
5. accessi VPN verso le VLAN su porte specifiche;
6. drop finale per tutto il resto.

## Flusso del traffico

### Traffico inter-VLAN

```text
VLAN 20 / Client
   |
   v
RouterOS
   |
   v
VLAN 30 / Server
```

### Traffico verso rete esterna

```text
VM interna
   |
   v
vmbr2 / Open vSwitch
   |
   v
RouterOS
   |
   v
ether1
   |
   v
pfSense
   |
   v
Rete esterna simulata
```

### Traffico VPN verso VLAN

```text
VPN 10.8.0.0/24
   |
   v
Proxmox / 10.3.0.254
   |
   v
RouterOS
   |
   v
VLAN interne
```

## File della directory

| File / Directory            | Descrizione                                   |
| --------------------------- | --------------------------------------------- |
| `README.md`                 | Panoramica del ruolo di RouterOS              |
| `interfaces.md`             | Interfacce fisiche e logiche                  |
| `vlans.md`                  | VLAN configurate e gateway                    |
| `routing.md`                | Rotte, default gateway e rete VPN             |
| `firewall-rules.md`         | Regole firewall e NAT                         |
| `sanitized-config-notes.md` | Note sulla sanificazione degli export         |
| `config/`                   | Configurazioni `.rsc` sanificate o di esempio |

## Export configurazione

Da RouterOS:

```text
/export hide-sensitive
```

Oppure per salvare su file:

```text
/export hide-sensitive file=routeros-config
```

Anche se `hide-sensitive` nasconde molti dati sensibili, controllare sempre manualmente il contenuto prima di fare commit.

## Configurazioni da non caricare

Non devono essere caricati nella repository:

* password;
* utenti reali;
* chiavi private;
* certificati;
* token;
* secret;
* configurazioni VPN sensibili;
* IP pubblici sensibili;
* export completi non controllati;
* commenti contenenti informazioni private.

## Relazione con Zeek

RouterOS influenza ciò che Zeek può osservare perché determina quali flussi attraversano le VLAN interne e `vmbr2`.

Per interpretare correttamente i log Zeek è importante sapere:

* quali VLAN sono instradate;
* quali gateway sono usati;
* quali rotte sono presenti;
* se il traffico attraversa il punto monitorato;
* se il traffico viene inoltrato verso pfSense;
* se il NAT modifica gli IP sorgente.

## Relazione con pfSense

RouterOS inoltra verso pfSense il traffico destinato alla rete esterna.

La default route punta a:

```text
10.4.0.253
```

pfSense riceve il traffico da RouterOS sulla rete:

```text
10.4.0.0/24
```

## Relazione con Wazuh

RouterOS non sostituisce Wazuh, ma influenza gli scenari osservati dagli host.

Se il routing o il firewall RouterOS non funzionano correttamente:

* gli host potrebbero non raggiungere i target;
* gli scenari potrebbero non generare gli eventi attesi;
* Wazuh potrebbe non ricevere eventi correlati;
* Zeek potrebbe non osservare il traffico previsto.

## Verifiche utili

Comandi RouterOS utili:

```text
/interface print
/interface vlan print detail
/ip address print detail
/ip route print detail
/ip firewall filter print detail
/ip firewall nat print detail
/ip dhcp-server print detail
/export hide-sensitive
```

## Note operative

* RouterOS è il gateway delle VLAN interne.
* `ether2` è il trunk VLAN verso `vmbr2`.
* `ether1` è l'uplink verso pfSense.
* La default route punta a pfSense.
* Il NAT masquerade è attivo verso `ether1`.
* Non è configurato un DHCP server su RouterOS.
* La regola finale `Drop everything else` blocca il traffico non esplicitamente consentito.

## Best practice

* documentare ogni VLAN;
* documentare ogni gateway;
* mantenere le rotte leggibili;
* controllare sempre gli export prima del commit;
* verificare il routing dopo ogni modifica;
* verificare che Zeek continui a vedere il traffico atteso;
* aggiornare la documentazione dopo ogni cambiamento;
* evitare di lasciare regole firewall non documentate.
