# pfSense

Questa directory contiene la documentazione e le configurazioni sanificate relative a pfSense.

pfSense è utilizzato come firewall tra la rete interna simulata e la rete esterna del laboratorio.

## Ruolo nel laboratorio

Nel progetto, pfSense rappresenta il punto di controllo tra:

* rete interna;
* RouterOS;
* rete esterna simulata;
* AttackerVM / Kali Linux.

Il suo compito principale è controllare il traffico tra l'infrastruttura interna e la rete esterna, applicando regole firewall, eventuale NAT e logging.

## Collegamenti logici

pfSense è collegato a due segmenti principali.

| Interfaccia pfSense | Interfaccia VM | IP / Subnet     | Ruolo                       | Collegamento |
| ------------------- | -------------- | --------------- | --------------------------- | ------------ |
| WAN                 | `vtnet0`       | `10.2.0.254/24` | Rete esterna simulata       | `vmbr1`      |
| LAN                 | `vtnet1`       | `10.4.0.253/24` | Collegamento verso RouterOS | `vmbr3`      |

## Gateway

| Gateway   | Interfaccia | IP Gateway | Ruolo                           |
| --------- | ----------- | ---------- | ------------------------------- |
| `WANGW_2` | WAN         | `10.2.0.1` | Gateway predefinito IPv4        |
| `LANGW`   | LAN         | `10.3.0.1` | Gateway lato interno / RouterOS |

## Percorso del traffico

Il traffico proveniente dalle VM interne verso la rete esterna segue questo percorso logico:

```text
VM interne
   |
   v
vmbr2 / Open vSwitch
   |
   v
RouterOS
   |
   v
vmbr3
   |
   v
pfSense
   |
   v
vmbr1
   |
   v
Rete esterna simulata / AttackerVM
```

Il traffico proveniente dalla macchina attaccante verso la rete interna segue il percorso inverso:

```text
AttackerVM / Kali Linux
   |
   v
vmbr1
   |
   v
pfSense
   |
   v
vmbr3
   |
   v
RouterOS
   |
   v
VLAN interne
```

## Funzioni principali

pfSense gestisce:

* filtraggio del traffico tra interno ed esterno;
* controllo delle comunicazioni in ingresso;
* controllo delle comunicazioni in uscita;
* NAT outbound automatico;
* logging firewall;
* separazione tra rete interna e rete attaccante;
* supporto agli scenari di attacco controllati.

## Configurazione attuale

Dal file di configurazione analizzato risultano questi elementi principali:

| Elemento             | Valore                        |
| -------------------- | ----------------------------- |
| Hostname             | `pfSense`                     |
| Dominio              | `home.arpa`                   |
| WAN                  | `vtnet0`                      |
| WAN IP               | `10.2.0.254/24`               |
| WAN gateway          | `10.2.0.1`                    |
| LAN                  | `vtnet1`                      |
| LAN IP               | `10.4.0.253/24`               |
| NAT outbound         | `automatic`                   |
| SSH                  | `enabled`                     |
| Regola firewall IPv4 | Default allow LAN to any      |
| Regola firewall IPv6 | Default allow LAN IPv6 to any |

## File della directory

Questa directory può contenere:

| File / Directory            | Descrizione                                       |
| --------------------------- | ------------------------------------------------- |
| `README.md`                 | Panoramica del ruolo di pfSense                   |
| `interfaces.md`             | Dettagli delle interfacce pfSense                 |
| `firewall-rules.md`         | Regole firewall attive, previste o sanificate     |
| `nat.md`                    | Configurazione NAT                                |
| `logging.md`                | Uso dei log pfSense per analisi e troubleshooting |
| `sanitized-config-notes.md` | Note sulla sanificazione dell'export pfSense      |
| `config/`                   | Configurazioni XML sanificate o esempi            |

## Configurazioni versionabili

È possibile versionare nella repository:

* documentazione delle interfacce;
* descrizione delle regole firewall;
* configurazioni NAT sanificate;
* esempi di log firewall sanificati;
* export XML sanificati;
* note operative sugli scenari.

## Configurazioni da non caricare

Non devono essere caricati nella repository:

* export pfSense originali non controllati;
* password;
* hash di password;
* utenti reali;
* chiavi private;
* certificati reali;
* configurazioni VPN contenenti segreti;
* token;
* IP pubblici sensibili;
* hostname personali se non necessari;
* log completi non sanificati.

## Export della configurazione

La configurazione pfSense può essere esportata dalla GUI:

```text
Diagnostics > Backup & Restore > Backup & Restore
```

Il file esportato è normalmente un file XML.

Prima di caricarlo nella repository, creare sempre una copia sanificata.

Esempio:

```text
network/pfsense/config/config-sanitized.xml
```

## Sanificazione

Prima del commit, controllare la presenza di dati sensibili.

Esempio di controllo:

```bash
grep -RniE "bcrypt|password|passwd|secret|key|private|cert|crt|prv|token|openvpn" network/pfsense/
```

Eventuali valori sensibili devono essere sostituiti con placeholder.

Esempi:

```text
REDACTED
PFSENSE_WAN_IP
PFSENSE_LAN_IP
WAN_GATEWAY
LAN_GATEWAY
ROUTEROS_IP
ATTACKER_IP
VICTIM_IP
INTERNAL_NET
EXTERNAL_NET
```

## Relazione con Zeek

pfSense controlla il traffico tra rete interna ed esterna.

Zeek osserva il traffico duplicato tramite mirroring su Open vSwitch, principalmente da `vmbr2`.

Per interpretare correttamente i log Zeek è importante sapere:

* quali flussi pfSense permette;
* quali flussi pfSense blocca;
* se è attivo NAT;
* se il traffico osservato da Zeek contiene IP originali o tradotti;
* se lo scenario attraversa effettivamente il punto di osservazione.

## Relazione con Wazuh

Wazuh osserva gli eventi sugli host monitorati.

I log pfSense possono aiutare a correlare:

* traffico bloccato o permesso;
* tentativi di accesso verso sistemi interni;
* connessioni generate durante una reverse shell;
* traffico di brute force;
* traffico di esfiltrazione;
* eventi host-based generati sugli endpoint.

## Uso nei principali scenari

| Scenario          | Ruolo di pfSense                                      |
| ----------------- | ----------------------------------------------------- |
| Reverse Shell     | Controlla traffico tra VictimVM e AttackerVM          |
| SSH Brute Force   | Regola traffico in ingresso verso host interni        |
| ICMP Flood        | Può permettere o bloccare traffico ICMP               |
| MITM / Spoofing   | Può fornire log sul traffico instradato verso esterno |
| Data Exfiltration | Controlla traffico in uscita verso rete esterna       |

## Verifiche utili

Da interfaccia web pfSense:

```text
Firewall > Rules
Firewall > NAT
Status > System Logs > Firewall
Diagnostics > Routes
Diagnostics > Ping
Diagnostics > Packet Capture
Diagnostics > States
```

Da console pfSense:

```sh
ifconfig
netstat -rn
pfctl -sr
pfctl -vvsr
```

## Note operative

Ogni modifica a pfSense dovrebbe essere documentata indicando:

* regola modificata;
* motivo della modifica;
* scenario coinvolto;
* traffico atteso;
* risultato osservato;
* eventuale impatto su Zeek;
* eventuale impatto su Wazuh.

## Best practice

* documentare le regole firewall in modo leggibile;
* evitare regole troppo permissive non motivate;
* abilitare logging sulle regole utili all'analisi;
* usare configurazioni sanificate;
* controllare sempre gli export XML prima del commit;
* verificare la connettività dopo ogni modifica;
* confrontare log pfSense, Zeek e Wazuh durante gli scenari.
