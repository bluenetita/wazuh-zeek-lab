# Zeek

Questa directory contiene la documentazione e le configurazioni sanificate relative a Zeek.

Zeek è utilizzato nel laboratorio come sistema di Network Security Monitoring per analizzare il traffico di rete duplicato tramite mirroring/SPAN su Open vSwitch.

## Ruolo nel laboratorio

Zeek fornisce visibilità a livello rete.

Il suo compito principale è osservare il traffico che attraversa l'infrastruttura interna e generare log strutturati utili per:

* analisi delle connessioni;
* identificazione dei protocolli;
* osservazione del traffico DNS, HTTP e TLS;
* analisi di traffico persistente;
* rilevamento di anomalie;
* supporto alla detection custom;
* correlazione con Wazuh.

## Punto di osservazione

Zeek riceve traffico duplicato tramite mirroring configurato su Open vSwitch.

Il punto principale di osservazione è:

```text
vmbr2 / Open vSwitch
```

Schema logico:

```text
VM interne / VLAN
   |
   v
vmbr2 / Open vSwitch
   |
   +--> traffico originale verso RouterOS / pfSense
   |
   +--> copia del traffico verso ZeekVM
```

## Reti osservate

Zeek è pensato per osservare il traffico relativo alle reti interne del laboratorio.

| VLAN | Nome       | Subnet         | Ruolo               |
| ---: | ---------- | -------------- | ------------------- |
|   10 | Monitoring | `10.3.10.0/24` | ZeekVM, WazuhVM     |
|   20 | Client     | `10.3.20.0/24` | ClientVM, WindowsVM |
|   30 | Server     | `10.3.30.0/24` | ServerDB, VictimVM  |

Il traffico verso l'esterno passa da RouterOS e pfSense.

## Relazione con gli altri componenti

| Componente   | Relazione con Zeek                                          |
| ------------ | ----------------------------------------------------------- |
| Proxmox VE   | Ospita la VM Zeek                                           |
| Open vSwitch | Duplica il traffico verso Zeek tramite mirror               |
| RouterOS     | Gestisce il routing tra VLAN e influenza i flussi osservati |
| pfSense      | Controlla traffico tra rete interna ed esterna              |
| Wazuh        | Può ricevere log custom o alert correlati agli eventi Zeek  |
| AttackerVM   | Genera traffico offensivo osservabile da Zeek               |
| VictimVM     | Target degli scenari osservati a livello rete               |

## Directory

| Directory / File   | Descrizione                                     |
| ------------------ | ----------------------------------------------- |
| `README.md`        | Panoramica del ruolo di Zeek                    |
| `etc/`             | File di configurazione principali Zeek          |
| `etc/node.cfg`     | Configurazione del nodo Zeek                    |
| `etc/networks.cfg` | Reti considerate locali                         |
| `etc/zeekctl.cfg`  | Configurazione ZeekControl                      |
| `site/`            | Configurazioni e script caricati da Zeek        |
| `site/local.zeek`  | Script principale caricato da Zeek              |
| `site/scripts/`    | Script custom di detection                      |
| `logs-samples/`    | Esempi di log sanificati                        |
| `systemd/`         | Servizi systemd collegati a Zeek o al mirroring |

## File di configurazione da versionare

I principali file da versionare sono:

```text
node.cfg
networks.cfg
zeekctl.cfg
local.zeek
site/scripts/
```

I percorsi originali possono variare in base al metodo di installazione.

Percorsi comuni:

```text
/opt/zeek/etc/
/opt/zeek/share/zeek/site/
```

oppure:

```text
/etc/zeek/
/usr/share/zeek/site/
```

## Log principali

Zeek genera log strutturati. I principali log utili nel laboratorio sono:

| Log          | Descrizione                                        |
| ------------ | -------------------------------------------------- |
| `conn.log`   | Connessioni osservate                              |
| `dns.log`    | Query e risposte DNS                               |
| `http.log`   | Traffico HTTP                                      |
| `tls.log`    | Metadati TLS                                       |
| `ssl.log`    | Metadati SSL/TLS, se presente nella versione usata |
| `weird.log`  | Eventi anomali                                     |
| `notice.log` | Notice e alert generati da Zeek                    |

## Log custom

Gli script custom possono generare log aggiuntivi.

Nel progetto sono previsti log per scenari come reverse shell, download sospetti e movimenti anomali.

Esempi:

| Log custom                   | Scopo                                                         |
| ---------------------------- | ------------------------------------------------------------- |
| `possible_malware.log`       | Possibile download o trasferimento di payload                 |
| `reverse_shell_live.log`     | Connessioni persistenti compatibili con reverse shell         |
| `reverse_shell_movement.log` | Pattern di traffico collegati a movimento o attività sospetta |
| `reverse_shell_final.log`    | Evento finale o classificazione dello scenario                |

## Comandi utili

Controllare la configurazione:

```bash
sudo zeekctl check
```

Applicare la configurazione:

```bash
sudo zeekctl deploy
```

Verificare lo stato:

```bash
sudo zeekctl status
```

Controllare log correnti:

```bash
sudo tail -f /opt/zeek/logs/current/conn.log
```

Verificare traffico sull'interfaccia di monitoraggio:

```bash
sudo tcpdump -i <interfaccia-zeek> -n
```

Verificare traffico con tag VLAN:

```bash
sudo tcpdump -i <interfaccia-zeek> -e -n
```

## Relazione con Wazuh

Zeek osserva il traffico di rete, mentre Wazuh osserva gli eventi sugli host.

La correlazione tra Zeek e Wazuh permette di collegare:

* connessioni sospette;
* download di payload;
* reverse shell;
* traffico persistente;
* modifiche locali rilevate da Wazuh;
* alert custom generati da regole Wazuh.

## Scenari supportati

Zeek è rilevante per diversi scenari:

| Scenario          | Evidenza Zeek attesa                                  |
| ----------------- | ----------------------------------------------------- |
| Reverse Shell     | Connessione TCP persistente verso AttackerVM          |
| Download Payload  | Eventi HTTP/TLS o log custom                          |

## Limiti

Zeek non può osservare direttamente:

* processi locali;
* comandi eseguiti sugli host;
* modifiche al filesystem;
* escalation di privilegi locali;
* eventi kernel-level;
* traffico non incluso nel mirror;
* contenuto applicativo cifrato.

Per questi aspetti è necessario integrare Zeek con Wazuh o con telemetria host-based aggiuntiva.

## Sanificazione

Non caricare nella repository:

* log completi non sanificati;
* PCAP completi;
* IP pubblici sensibili;
* payload;
* file malevoli;
* credenziali;
* chiavi private;
* token;
* dati personali.

Eventuali esempi di log devono essere ridotti e sanificati.

## Note operative

Ogni modifica a Zeek dovrebbe essere documentata indicando:

* file modificato;
* motivo della modifica;
* scenario interessato;
* risultato di `zeekctl check`;
* risultato osservato nei log;
* eventuale correlazione con Wazuh.

## Best practice

* mantenere versionati i file di configurazione;
* usare script custom separati in `site/scripts/`;
* documentare ogni log custom;
* verificare sempre la sintassi con `zeekctl check`;
* fare deploy dopo ogni modifica;
* testare con traffico controllato;
* controllare che il mirror OVS funzioni correttamente;
* non caricare log grezzi o PCAP nella repository.
