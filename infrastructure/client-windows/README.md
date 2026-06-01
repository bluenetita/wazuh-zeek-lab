# Client Windows

Questa directory contiene la documentazione relativa alla VM Windows client utilizzata nel laboratorio.

## Ruolo nel laboratorio

`WindowsVM` rappresenta un endpoint Windows interno dell'infrastruttura aziendale simulata.

Il suo ruolo è simulare una macchina client Windows appartenente alla rete interna, utile per generare traffico legittimo, produrre eventi host-based e partecipare ad alcuni scenari di test.

## Posizione nella rete

| Campo          | Valore           |
| -------------- | ---------------- |
| Nome VM        | `WindowsVM`      |
| Tipo           | Client Windows   |
| VLAN           | VLAN 20 - Client |
| Subnet         | `10.3.20.0/24`   |
| Gateway        | `10.3.20.1`      |
| Gateway device | RouterOS         |

## Ruolo della VLAN

La VM si trova nella VLAN 20, dedicata agli endpoint client.

Questa VLAN rappresenta il segmento utente della rete aziendale simulata e contiene anche il client Linux.

## Connettività

### Verso server interni

```text
WindowsVM
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
WindowsVM
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

* simulare un endpoint Windows aziendale;
* generare traffico DNS, HTTP e HTTPS;
* comunicare con server interni;
* testare connettività inter-VLAN;
* produrre eventi Windows raccolti da Wazuh;
* osservare differenze tra telemetria Linux e Windows;
* partecipare a scenari di spoofing, MITM o traffico client-server.

## Relazione con Zeek

Zeek può osservare il traffico generato da `WindowsVM` se il traffico attraversa il punto di mirroring configurato su Open vSwitch.

Evidenze possibili nei log Zeek:

| Log Zeek    | Evidenza                       |
| ----------- | ------------------------------ |
| `conn.log`  | Connessioni verso altri host   |
| `dns.log`   | Query DNS generate dal client  |
| `http.log`  | Richieste HTTP                 |
| `tls.log`   | Metadati TLS                   |
| `weird.log` | Eventuali anomalie di traffico |

## Relazione con Wazuh

Se l'agent Wazuh è installato su `WindowsVM`, il sistema può produrre eventi host-based.

Esempi:

* eventi Windows;
* autenticazioni;
* log di sicurezza;
* log di sistema;
* eventi applicativi;
* informazioni di inventory;
* eventuali alert custom;
* attività osservabile tramite EventChannel.

## Wazuh Agent

Se l'agent Wazuh è installato, la configurazione può essere verificata sul sistema Windows.

Percorso tipico:

```text
C:\Program Files (x86)\ossec-agent\ossec.conf
```

Servizio Windows:

```text
Wazuh Agent
```

Verifiche utili:

```powershell
Get-Service -Name WazuhSvc
```

Oppure tramite interfaccia grafica:

```text
Services > Wazuh Agent
```

## Eventi Windows utili

La VM Windows può produrre eventi utili per:

| Categoria        | Esempi                                   |
| ---------------- | ---------------------------------------- |
| Security         | Logon, logoff, failed logon              |
| System           | Avvio/arresto servizi, errori di sistema |
| Application      | Eventi applicativi                       |
| PowerShell       | Comandi o script, se logging abilitato   |
| Windows Defender | Eventi antivirus, se attivo              |
| RDP              | Connessioni remote, se abilitate         |

## Scenari collegati

`WindowsVM` può essere coinvolta in diversi scenari:

| Scenario                | Ruolo della VM                                       |
| ----------------------- | ---------------------------------------------------- |
| Test traffico legittimo | Genera traffico normale verso server o rete esterna  |
| MITM / Spoofing         | Possibile vittima o sorgente di traffico osservabile |
| Data Exfiltration       | Possibile sorgente di traffico in uscita             |
| RDP / Accessi remoti    | Possibile target o client di connessioni remote      |
| Correlazione Zeek-Wazuh | Produce traffico rete e eventi host Windows          |

## Verifiche utili

Verificare configurazione IP:

```powershell
ipconfig /all
```

Verificare routing:

```powershell
route print
```

Verificare raggiungibilità del gateway:

```powershell
ping 10.3.20.1
```

Verificare DNS:

```powershell
nslookup example.com
```

Verificare connettività verso server interni:

```powershell
ping <SERVER_IP>
```

Verificare stato agent Wazuh:

```powershell
Get-Service -Name WazuhSvc
```

## Configurazioni da versionare

È possibile versionare in questa directory:

* note di setup;
* configurazioni sanificate;
* configurazioni Wazuh agent se modificate;
* script PowerShell non sensibili;
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
* dump di memoria;
* payload;
* malware;
* file generati durante scenari offensivi.

## Note operative

Questa VM rappresenta un endpoint Windows interno.

Se la configurazione dell'agent Wazuh rimane standard, non è necessario versionare `ossec.conf`.

Aggiungere file specifici solo se vengono configurati EventChannel, logging PowerShell, regole locali o monitoraggi custom.

## Best practice

* documentare solo configurazioni utili;
* evitare di caricare file personali o runtime;
* non duplicare configurazioni standard non modificate;
* aggiornare questa documentazione se cambiano IP, VLAN, servizi o ruolo della VM;
* collegare la VM agli scenari in cui viene effettivamente usata.
