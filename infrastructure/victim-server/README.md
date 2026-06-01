# Victim Server

Questa directory contiene la documentazione relativa alla VM vulnerabile utilizzata come target negli scenari di attacco del laboratorio.

## Ruolo nel laboratorio

`VictimVM` rappresenta un server vulnerabile interno all'infrastruttura aziendale simulata ed è basata su Metasploitable3.

Il suo ruolo è fornire un target controllato per eseguire scenari offensivi e osservare come Zeek e Wazuh rilevano attività malevole o sospette.

## Posizione nella rete

| Campo          | Valore                      |
| -------------- | --------------------------- |
| Nome VM        | `VictimVM`                  |
| Tipo           | Server vulnerabile / target |
| Sistema        | Metasploitable3             |
| VLAN           | VLAN 30 - Server            |
| Subnet         | `10.3.30.0/24`              |
| Gateway        | `10.3.30.1`                 |
| Gateway device | RouterOS                    |

## Ruolo della VLAN

La VM si trova nella VLAN 30, dedicata ai server interni.

Questa VLAN contiene sistemi che espongono servizi e che possono essere usati come target negli scenari controllati.

## Sistema e servizi

La VictimVM è basata su Metasploitable3, una macchina volutamente vulnerabile utilizzata nel laboratorio come target controllato per attività di detection.

Questa VM permette di simulare un server vulnerabile interno alla rete aziendale e di osservare evidenze generate da:

* Zeek a livello network-based;
* Wazuh a livello host-based;
* pfSense a livello firewall;
* RouterOS a livello routing/inter-VLAN.

## Servizi esposti

Metasploitable3 può esporre diversi servizi vulnerabili o utili per scenari controllati.

Documentare solo i servizi effettivamente usati nel laboratorio.

| Servizio |      Porta | Uso nel laboratorio                           |
| -------- | ---------: | --------------------------------------------- |
| SSH      |   `22/tcp` | Accesso remoto / brute force controllato      |
| HTTP     |   `80/tcp` | Servizio web di test                          |
| SMB      |  `445/tcp` | Enumerazione o scenario controllato, se usato |
| WinRM    | `5985/tcp` | Gestione remota, se presente                  |
| Altro    |        TBD | Da documentare se usato                       |

## Connettività

### AttackerVM verso VictimVM

```text
AttackerVM / Kali
   |
   v
Rete esterna simulata
   |
   v
pfSense
   |
   v
RouterOS
   |
   v
VLAN 30
   |
   v
VictimVM / Metasploitable3
```

### VictimVM verso AttackerVM

```text
VictimVM / Metasploitable3
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
AttackerVM / Kali
```

Questo percorso è particolarmente importante per scenari come reverse shell, download di payload o data exfiltration.

## Relazione con Zeek

Zeek può osservare il traffico generato o ricevuto dalla VictimVM se il traffico attraversa il punto di mirroring configurato su Open vSwitch.

Evidenze possibili nei log Zeek:

| Log Zeek        | Evidenza                                            |
| --------------- | --------------------------------------------------- |
| `conn.log`      | Connessioni verso o dalla VictimVM                  |
| `dns.log`       | Query DNS generate dalla VictimVM                   |
| `http.log`      | Download di payload o traffico web                  |
| `tls.log`       | Metadati TLS, se presenti                           |
| `weird.log`     | Eventuali anomalie                                  |
| Log custom Zeek | Reverse shell, possibile malware, traffico sospetto |

## Relazione con Wazuh

Se l'agent Wazuh è installato sulla VictimVM, il sistema può produrre eventi host-based.

Esempi:

* autenticazioni riuscite o fallite;
* eventi SSH;
* modifiche al filesystem;
* eventi File Integrity Monitoring;
* processi sospetti;
* modifiche a configurazioni;
* log di sistema;
* eventuali alert custom.

## Scenari collegati

VictimVM è uno dei principali target degli scenari del laboratorio.

| Scenario                | Ruolo della VictimVM                                        |
| ----------------------- | ----------------------------------------------------------- |
| Reverse Shell           | Host compromesso che apre una connessione verso AttackerVM  |
| Privilege Escalation    | Target su cui osservare attività locali post-compromissione |
| SSH Brute Force         | Target di tentativi di autenticazione                       |
| ICMP Flood              | Possibile target di traffico ICMP elevato                   |
| Data Exfiltration       | Host da cui possono essere esfiltrati file o dati           |
| Download Payload        | Host che scarica un payload da AttackerVM                   |
| Correlazione Zeek-Wazuh | Genera traffico rete e possibili eventi host-based          |

## Evidenze attese

Durante gli scenari, VictimVM può generare evidenze su più livelli.

| Fonte       | Evidenza possibile                                      |
| ----------- | ------------------------------------------------------- |
| Zeek        | Connessioni, durata, byte trasferiti, porte, log custom |
| Wazuh       | Autenticazioni, FIM, processi, file modificati, alert   |
| pfSense     | Traffico permesso o bloccato                            |
| RouterOS    | Traffico inter-VLAN o verso WAN                         |
| Host locale | Log di sistema e servizi                                |

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

Verificare porte in ascolto:

```bash
ss -tulpn
```

Verificare servizi attivi:

```bash
systemctl --type=service --state=running
```

Verificare stato agent Wazuh:

```bash
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
```

Verificare log di autenticazione:

```bash
sudo tail -f /var/log/auth.log
```

## Configurazioni da versionare

È possibile versionare in questa directory:

* note di setup;
* lista dei servizi effettivamente usati;
* configurazioni sanificate;
* configurazioni Wazuh agent se modificate;
* script di test non offensivi;
* esempi di log sanificati;
* note sugli scenari in cui la VM è coinvolta.

## Configurazioni da non versionare

Non caricare:

* password;
* token;
* chiavi private;
* certificati privati;
* exploit;
* payload;
* malware;
* reverse shell pronte all'uso;
* dump di memoria;
* file generati durante compromissioni;
* log completi;
* alert completi;
* dati personali.

## Note operative

Questa VM deve essere usata solo in un ambiente controllato e isolato.

La documentazione deve descrivere il ruolo della VictimVM negli scenari senza includere materiale pericoloso, credenziali o payload reali.

Se in futuro vengono aggiunti servizi specifici, configurazioni particolari o note sugli scenari, aggiornare questo file e aggiungere eventuali sotto-directory dedicate.

## Best practice

* documentare solo attività svolte nel laboratorio;
* indicare chiaramente che la VM è basata su Metasploitable3;
* mantenere separati scenari, evidenze e configurazioni;
* non versionare payload o exploit;
* usare esempi sanificati;
* collegare la VM agli scenari in cui viene effettivamente usata;
* aggiornare la documentazione se cambiano IP, VLAN, servizi o ruolo della VM.
