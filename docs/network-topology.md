# Network Topology

Questo documento descrive la topologia di rete del cyber range, includendo bridge Proxmox, VLAN, subnet, gateway e percorsi principali del traffico.

## Obiettivo

L'obiettivo di questo documento è fornire una vista chiara della rete virtuale utilizzata nel laboratorio.

La topologia descrive:

* segmenti di rete;
* bridge Proxmox;
* VLAN interne;
* gateway RouterOS;
* collegamento con pfSense;
* rete esterna simulata;
* traffico mirrorato verso Zeek;
* percorso tra AttackerVM e Client Linux.

## Panoramica

Il laboratorio è composto da una rete esterna simulata e da più segmenti interni separati tramite VLAN.

La rete interna è instradata da RouterOS, mentre pfSense controlla il traffico tra rete esterna simulata e rete interna.

Open vSwitch su Proxmox viene utilizzato per duplicare il traffico verso Zeek.

## Schema logico generale

```text
AttackerVM / Kali
   |
   v
vmbr1 - Rete esterna simulata
   |
   v
pfSense
   |
   v
vmbr3 - Transito pfSense/RouterOS
   |
   v
RouterOS
   |
   v
vmbr2 - Rete interna / VLAN trunk
   |
   +--> VLAN 10 - Monitoring
   |       +--> ZeekVM
   |       +--> WazuhVM
   |
   +--> VLAN 20 - Client
   |       +--> Client Linux / ClientVM
   |       +--> Client Windows / WindowsVM
   |
   +--> VLAN 30 - Server
           +--> ServerDB
           +--> Victim Server / Metasploitable3
```

## Bridge Proxmox

| Bridge       | Ruolo                   | Note                                          |
| ------------ | ----------------------- | --------------------------------------------- |
| `vmbr1`      | Rete esterna simulata   | Collega AttackerVM e pfSense                  |
| `vmbr2`      | Rete interna principale | Bridge OVS usato per VLAN e mirror verso Zeek |
| `vmbr3`      | Rete di transito        | Collegamento tra pfSense e RouterOS           |
| `vmbr4-test` | Rete di test            | Segmento separato per test o esperimenti      |

## VLAN interne

| VLAN | Nome       | Subnet                   | Gateway     | Ruolo                                   |
| ---: | ---------- | ------------------------ | ----------- | --------------------------------------- |
|   10 | Monitoring | `10.3.10.0/24`           | `10.3.10.1` | ZeekVM e WazuhVM                        |
|   20 | Client     | `10.3.20.0/24`           | `10.3.20.1` | Client Linux e Client Windows           |
|   30 | Server     | `10.3.30.0/24`           | `10.3.30.1` | ServerDB e Victim Server                |
|  999 | Mirror     | Nessun gateway operativo | N/A         | Trasporto traffico mirrorato verso Zeek |

## Reti di transito e test

| Rete          | Ruolo                              | Dispositivo principale                      |
| ------------- | ---------------------------------- | ------------------------------------------- |
| `10.2.0.0/24` | Rete esterna simulata / AttackerVM | pfSense lato esterno                        |
| `10.4.0.0/24` | Transito RouterOS-pfSense          | RouterOS `10.4.0.252`, pfSense `10.4.0.253` |
| `10.5.0.0/24` | Rete test                          | RouterOS `10.5.0.1`                         |
| `10.8.0.0/24` | Rete VPN                           | Gateway via Proxmox `10.3.0.254`            |

## Dispositivi principali

| Sistema                         | Ruolo                           | Segmento                        |
| ------------------------------- | ------------------------------- | ------------------------------- |
| AttackerVM / Kali               | Macchina red team               | Rete esterna simulata           |
| pfSense                         | Firewall                        | Tra rete esterna e RouterOS     |
| RouterOS                        | Router inter-VLAN               | VLAN interne e transito pfSense |
| ZeekVM                          | Network Security Monitoring     | VLAN Monitoring + VLAN Mirror   |
| WazuhVM                         | Wazuh Manager                   | VLAN Monitoring                 |
| Client Linux / ClientVM         | Target principale degli scenari | VLAN Client                     |
| Client Windows / WindowsVM      | Endpoint Windows interno        | VLAN Client                     |
| ServerDB                        | Server PostgreSQL               | VLAN Server                     |
| Victim Server / Metasploitable3 | Server vulnerabile documentato  | VLAN Server                     |

## RouterOS

RouterOS gestisce il routing inter-VLAN.

Gateway principali:

| Interfaccia / VLAN         | IP              |
| -------------------------- | --------------- |
| VLAN 10                    | `10.3.10.1/24`  |
| VLAN 20                    | `10.3.20.1/24`  |
| VLAN 30                    | `10.3.30.1/24`  |
| WAN/transito verso pfSense | `10.4.0.252/24` |
| Rete test                  | `10.5.0.1/24`   |

Default route RouterOS:

```text
0.0.0.0/0 -> 10.4.0.253
```

Route VPN:

```text
10.8.0.0/24 -> 10.3.0.254
```

## pfSense

pfSense separa la rete esterna simulata dalla rete interna.

| Interfaccia logica | Segmento                | Ruolo                       |
| ------------------ | ----------------------- | --------------------------- |
| WAN / External     | `vmbr1` / `10.2.0.0/24` | Rete esterna simulata       |
| Internal / Transit | `vmbr3` / `10.4.0.0/24` | Collegamento verso RouterOS |

Nel laboratorio pfSense riceve traffico dalla rete esterna simulata e lo inoltra, se consentito, verso RouterOS.

## AttackerVM

AttackerVM è basata su Kali Linux e si trova nella rete esterna simulata.

Configurazione documentata:

```text
red-team/attacker-kali/
red-team/attacker-kali/network/
```

Configurazione di rete osservata:

| Interfaccia | IP            | Gateway    |
| ----------- | ------------- | ---------- |
| `eth0`      | `10.2.0.2/24` | `10.2.0.1` |
| `eth1`      | `10.2.0.3/24` | `10.2.0.1` |

## Client Linux

Client Linux è il target principale degli scenari simulati.

Si trova nella VLAN Client:

```text
VLAN 20 - 10.3.20.0/24
```

Documentazione correlata:

```text
infrastructure/client-linux/
```

## Percorso AttackerVM verso Client Linux

```text
AttackerVM / Kali
   |
   v
10.2.0.0/24
   |
   v
pfSense
   |
   v
10.4.0.0/24
   |
   v
RouterOS
   |
   v
VLAN 20 - Client
   |
   v
Client Linux
```

## Percorso Client Linux verso AttackerVM

```text
Client Linux
   |
   v
VLAN 20 - Client
   |
   v
RouterOS
   |
   v
10.4.0.0/24
   |
   v
pfSense
   |
   v
10.2.0.0/24
   |
   v
AttackerVM / Kali
```

## Mirroring verso Zeek

Il traffico delle VLAN interne viene duplicato da Open vSwitch verso Zeek.

Mirror configurato:

| Parametro        | Valore           |
| ---------------- | ---------------- |
| Bridge           | `vmbr2`          |
| Mirror name      | `zeek_mirror`    |
| VLAN selezionate | `10`, `20`, `30` |
| Output VLAN      | `999`            |

Schema:

```text
Traffico VLAN 10 / 20 / 30
   |
   v
vmbr2 / OVS
   |
   +--> traffico originale
   |
   +--> copia su VLAN 999
           |
           v
        ZeekVM
```

## ZeekVM

Zeek riceve traffico mirrorato tramite interfacce dedicate.

Interfacce documentate:

| Interfaccia | Ruolo                        |
| ----------- | ---------------------------- |
| `ens18`     | Management / VLAN Monitoring |
| `ens19`     | Interfaccia di monitoraggio  |
| `ens19.999` | VLAN mirror verso Zeek       |

Configurazione correlata:

```text
blue-team/zeek/netplan/
blue-team/zeek/systemd/
proxmox/ovs/
```

## WazuhVM

WazuhVM si trova nella VLAN Monitoring e riceve eventi dagli agent Wazuh.

Wazuh riceve anche log custom Zeek tramite l'agent installato su ZeekVM.

Flusso:

```text
Zeek logs
   |
   v
Wazuh Agent su ZeekVM
   |
   v
Wazuh Manager
   |
   v
Alert
```

## ServerDB

ServerDB si trova nella VLAN Server ed espone PostgreSQL.

Documentazione correlata:

```text
infrastructure/server-db/
```

## Victim Server

Victim Server è basato su Metasploitable3 ed è documentato come server vulnerabile interno.

Documentazione correlata:

```text
infrastructure/victim-server/
```

## Tabella riassuntiva segmenti

| Segmento   | Subnet         | Gateway      | Sistemi principali           |
| ---------- | -------------- | ------------ | ---------------------------- |
| External   | `10.2.0.0/24`  | `10.2.0.1`   | AttackerVM, pfSense          |
| Monitoring | `10.3.10.0/24` | `10.3.10.1`  | ZeekVM, WazuhVM              |
| Client     | `10.3.20.0/24` | `10.3.20.1`  | Client Linux, Client Windows |
| Server     | `10.3.30.0/24` | `10.3.30.1`  | ServerDB, Victim Server      |
| Transit    | `10.4.0.0/24`  | N/A          | RouterOS, pfSense            |
| Test       | `10.5.0.0/24`  | `10.5.0.1`   | Rete test                    |
| VPN        | `10.8.0.0/24`  | `10.3.0.254` | Accesso VPN                  |

## Verifiche utili

### Proxmox

```bash
ip link show
ovs-vsctl show
ovs-vsctl list mirror
```

### RouterOS

```text
/ip address print detail
/ip route print detail
/ip firewall filter print detail
/ip firewall nat print detail
```

### pfSense

```bash
ifconfig
netstat -rn
pfctl -sr
```

### ZeekVM

```bash
ip addr
sudo tcpdump -i ens19 -n
sudo tcpdump -i ens19.999 -n
sudo /opt/zeek/bin/zeekctl status
```

### AttackerVM

```bash
ip -br addr
ip route
cat /etc/resolv.conf
```

### Client Linux

```bash
ip addr
ip route
ping 10.3.20.1
```

## Note operative

* RouterOS è il router principale delle VLAN interne.
* pfSense controlla il traffico tra rete esterna simulata e rete interna.
* Proxmox fornisce bridge e switching virtuale.
* OVS duplica il traffico verso Zeek.
* Zeek osserva traffico network-based.
* Wazuh osserva eventi host-based e alert derivati da Zeek.
* Client Linux è il target principale degli scenari simulati.

## Directory correlate

| Directory                 | Descrizione                             |
| ------------------------- | --------------------------------------- |
| `proxmox/`                | Bridge, OVS, routing e virtualizzazione |
| `network/pfsense/`        | Configurazione pfSense                  |
| `network/routeros/`       | Configurazione RouterOS                 |
| `blue-team/zeek/`         | Configurazione Zeek                     |
| `blue-team/wazuh/`        | Configurazione Wazuh                    |
| `red-team/attacker-kali/` | Configurazione AttackerVM               |
| `infrastructure/`         | VM interne                              |
| `scenarios/`              | Scenari simulati                        |
| `evidence/`               | Evidenze sanificate                     |

## Best practice

* mantenere aggiornata la topologia quando cambiano IP, VLAN o bridge;
* verificare sempre routing e firewall dopo modifiche;
* controllare il mirror OVS dopo reboot o modifiche Proxmox;
* mantenere coerenti `docs/network-topology.md`, `proxmox/network-bridges.md` e `proxmox/routing.md`;
* non inserire credenziali, token o output non sanificati.
