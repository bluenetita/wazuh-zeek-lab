# Client Linux

Questa directory contiene la documentazione relativa alla VM Linux client utilizzata nel laboratorio.

## Ruolo nel laboratorio

`ClientVM` rappresenta un endpoint Linux interno dell'infrastruttura aziendale simulata.

Il suo ruolo è simulare una macchina client appartenente alla rete interna, utilizzata per generare traffico legittimo, partecipare agli scenari di test e produrre eventi host-based raccolti da Wazuh.

## Posizione nella rete

| Campo          | Valore           |
| -------------- | ---------------- |
| Nome VM        | `ClientVM`       |
| Tipo           | Client Linux     |
| VLAN           | VLAN 20 - Client |
| Subnet         | `10.3.20.0/24`   |
| Gateway        | `10.3.20.1`      |
| Gateway device | RouterOS         |

## Ruolo della VLAN

La VM si trova nella VLAN 20, dedicata agli endpoint client.

Questa VLAN rappresenta il segmento utente della rete aziendale simulata.

## Connettività

Il traffico generato dal client Linux può seguire diversi percorsi.

### Verso server interni

```text
ClientVM
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
ServerDB / VictimVM
```

### Verso rete esterna

```text
ClientVM
   |
   v
VLAN 20
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

## Servizi e funzioni

La VM può essere usata per:

* generare traffico HTTP/HTTPS;
* generare query DNS;
* comunicare con server interni;
* testare connettività inter-VLAN;
* produrre eventi host-based per Wazuh;
* simulare attività di un endpoint aziendale;
* partecipare a scenari di attacco o movimento laterale.

## Relazione con Zeek

Zeek può osservare il traffico generato da `ClientVM` se il traffico attraversa il punto di mirroring configurato su Open vSwitch.

Evidenze possibili nei log Zeek:

| Log Zeek    | Evidenza                       |
| ----------- | ------------------------------ |
| `conn.log`  | Connessioni verso altri host   |
| `dns.log`   | Query DNS generate dal client  |
| `http.log`  | Richieste HTTP                 |
| `tls.log`   | Metadati TLS                   |
| `weird.log` | Eventuali anomalie di traffico |

## Relazione con Wazuh

Se l'agent Wazuh è installato su `ClientVM`, il sistema può produrre eventi host-based.

Esempi:

* autenticazioni;
* log di sistema;
* modifiche al filesystem;
* eventi File Integrity Monitoring;
* inventory di sistema;
* processi e servizi;
* eventuali alert custom.

## Scenari collegati

`ClientVM` può essere coinvolta in diversi scenari:

| Scenario                | Ruolo della VM                                         |
| ----------------------- | ------------------------------------------------------ |
| Test traffico legittimo | Genera traffico normale verso server o rete esterna    |
| Data Exfiltration       | Possibile sorgente di traffico in uscita               |
| MITM / Spoofing         | Possibile vittima o generatore di traffico osservabile |
| SSH / accessi interni   | Possibile sorgente o destinazione di connessioni       |
| Correlazione Zeek-Wazuh | Produce traffico rete e eventi host                    |

## Verifiche utili

Verificare configurazione IP:

```bash
ip addr
ip route
```

Verificare raggiungibilità del gateway:

```bash
ping 10.3.20.1
```

Verificare DNS:

```bash
nslookup example.com
```

Verificare connettività verso server interni:

```bash
ping <SERVER_IP>
```

Verificare stato agent Wazuh:

```bash
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
```

## Configurazioni da versionare

È possibile versionare in questa directory:

* configurazioni sanificate;
* note di setup;
* configurazioni Wazuh agent se modificate;
* script non sensibili;
* esempi di log sanificati.

## Configurazioni da non versionare

Non caricare:

* password;
* token;
* chiavi private;
* certificati privati;
* file personali;
* log completi;
* alert completi;
* payload;
* malware;
* file generati durante scenari offensivi.

## Note operative

Questa VM rappresenta un endpoint interno.

Non deve essere documentata come target principale vulnerabile, ma come client aziendale usato per generare traffico e supportare gli scenari.

Se in futuro vengono aggiunti servizi, configurazioni particolari o modifiche all'agent Wazuh, aggiornare questo file.
