# Proxmox Routing Notes

Questo documento descrive il ruolo dell'host Proxmox nel percorso del traffico del laboratorio.

## Obiettivo

L'obiettivo di questo file è chiarire come il traffico attraversa l'ambiente virtualizzato e quale ruolo hanno Proxmox, Open vSwitch, RouterOS e pfSense.

Nel laboratorio, Proxmox non svolge il ruolo di router principale.

Il routing è gestito principalmente da:

* RouterOS, per il routing inter-VLAN;
* pfSense, per il traffico tra rete interna e rete esterna simulata.

Proxmox fornisce invece:

* bridge virtuali;
* collegamenti tra VM;
* trasporto delle VLAN;
* mirroring del traffico verso Zeek.

## Ruolo di Proxmox

Proxmox agisce come layer di virtualizzazione e switching.

Nel laboratorio ospita le VM e le collega ai bridge corretti.

| Componente   | Ruolo                                  |
| ------------ | -------------------------------------- |
| Proxmox      | Host di virtualizzazione               |
| Open vSwitch | Switching virtuale e mirroring         |
| RouterOS     | Routing inter-VLAN                     |
| pfSense      | Firewall e traffico verso rete esterna |
| Zeek         | Monitoraggio network-based             |
| Wazuh        | Monitoraggio host-based                |

## Bridge coinvolti

| Bridge       | Ruolo                            |
| ------------ | -------------------------------- |
| `vmbr1`      | Rete esterna simulata            |
| `vmbr2`      | Rete interna principale con VLAN |
| `vmbr3`      | Collegamento RouterOS-pfSense    |
| `vmbr4-test` | Rete di test separata            |

## Routing inter-VLAN

Il routing tra VLAN interne è gestito da RouterOS.

Le VLAN principali sono:

| VLAN | Nome       | Subnet         | Gateway     |
| ---: | ---------- | -------------- | ----------- |
|   10 | Monitoring | `10.3.10.0/24` | `10.3.10.1` |
|   20 | Client     | `10.3.20.0/24` | `10.3.20.1` |
|   30 | Server     | `10.3.30.0/24` | `10.3.30.1` |

Le VM usano RouterOS come gateway della propria VLAN.

## Reti principali

| Rete           | Ruolo                     | Gateway / Nodo principale                   |
| -------------- | ------------------------- | ------------------------------------------- |
| `10.3.10.0/24` | VLAN Monitoring           | RouterOS `10.3.10.1`                        |
| `10.3.20.0/24` | VLAN Client               | RouterOS `10.3.20.1`                        |
| `10.3.30.0/24` | VLAN Server               | RouterOS `10.3.30.1`                        |
| `10.4.0.0/24`  | Transito RouterOS-pfSense | RouterOS `10.4.0.252`, pfSense `10.4.0.253` |
| `10.5.0.0/24`  | Rete test                 | RouterOS `10.5.0.1`                         |
| `10.8.0.0/24`  | VPN via Proxmox           | Gateway `10.3.0.254`                        |

## Default route RouterOS

RouterOS inoltra il traffico verso pfSense usando la default route:

```text id="ku2ww8"
0.0.0.0/0 -> 10.4.0.253
```

Dove:

| IP           | Ruolo                         |
| ------------ | ----------------------------- |
| `10.4.0.252` | RouterOS lato WAN/transito    |
| `10.4.0.253` | pfSense lato interno/transito |

## Route VPN

RouterOS contiene anche una rotta verso la rete VPN:

```text id="cva7uv"
10.8.0.0/24 -> 10.3.0.254
```

Questa rotta permette di raggiungere la rete VPN tramite Proxmox.

## Percorso traffico interno

Esempio: Client Linux verso ServerDB.

```text id="wpgcic"
ClientVM
   |
   v
VLAN 20
   |
   v
vmbr2 / OVS
   |
   v
RouterOS
   |
   v
VLAN 30
   |
   v
ServerDB
```

## Percorso traffico verso esterno

Esempio: VictimVM verso AttackerVM.

```text id="ld6sqc"
VictimVM
   |
   v
VLAN 30
   |
   v
vmbr2 / OVS
   |
   v
RouterOS
   |
   v
vmbr3 / transito
   |
   v
pfSense
   |
   v
vmbr1 / rete esterna simulata
   |
   v
AttackerVM
```

## Percorso traffico da esterno verso interno

Esempio: AttackerVM verso VictimVM.

```text id="zv27oe"
AttackerVM
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
vmbr2 / OVS
   |
   v
VLAN 30
   |
   v
VictimVM
```

## Percorso traffico VPN

Esempio: host VPN verso VLAN interne.

```text id="bapljb"
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

## Relazione con OVS mirror

Il traffico che attraversa `vmbr2` può essere duplicato verso Zeek tramite mirror OVS.

Il mirror seleziona le VLAN:

```text id="6lpyqv"
10, 20, 30
```

e invia una copia su:

```text id="l16idz"
VLAN 999
```

Schema:

```text id="gqd4j2"
vmbr2 / OVS
   |
   +--> traffico originale verso RouterOS / VM
   |
   +--> copia VLAN 999 verso Zeek
```

## Relazione con Zeek

Zeek osserva il traffico duplicato, ma non modifica il routing.

Zeek è passivo rispetto al percorso del traffico.

Se Zeek non vede un flusso, verificare:

* se il traffico attraversa `vmbr2`;
* se la VLAN è inclusa nel mirror;
* se la VLAN 999 arriva alla VM Zeek;
* se l'interfaccia Zeek è corretta;
* se l'interfaccia è in modalità promiscua.

## Relazione con pfSense

pfSense controlla il traffico tra rete interna e rete esterna simulata.

pfSense è raggiunto da RouterOS tramite la rete di transito `10.4.0.0/24`.

## Relazione con RouterOS

RouterOS è il router principale delle VLAN interne.

Le configurazioni RouterOS sono documentate in:

```text id="ynmj4y"
network/routeros/
```

## Verifiche su Proxmox

Visualizzare bridge e interfacce:

```bash id="4iqsjc"
ip link show
```

Visualizzare OVS:

```bash id="ejm77a"
ovs-vsctl show
```

Visualizzare porte su `vmbr2`:

```bash id="5y4ryi"
ovs-vsctl list-ports vmbr2
```

Verificare mirror:

```bash id="q3rv8c"
ovs-vsctl list mirror
```

Verificare routing host Proxmox:

```bash id="yhw0nt"
ip route
```

## Verifiche su RouterOS

```text id="15q4t6"
/ip address print detail
/ip route print detail
/ip firewall filter print detail
/ip firewall nat print detail
```

## Verifiche su pfSense

Da console o shell pfSense:

```bash id="b8e2bu"
ifconfig
netstat -rn
pfctl -sr
```

## Troubleshooting

### Una VM non raggiunge un'altra VLAN

Verificare:

* VLAN della VM;
* gateway configurato sulla VM;
* bridge Proxmox assegnato;
* trunk VLAN su `vmbr2`;
* indirizzi su RouterOS;
* regole firewall RouterOS.

### Una VM non raggiunge l'esterno

Verificare:

* default route della VM;
* default route RouterOS verso `10.4.0.253`;
* collegamento RouterOS-pfSense;
* NAT RouterOS;
* regole pfSense;
* connettività su `vmbr1`.

### Zeek non vede il traffico

Verificare:

* mirror su `vmbr2`;
* VLAN selezionate nel mirror;
* output VLAN 999;
* interfaccia Zeek;
* servizi systemd Zeek per modalità promiscua;
* `tcpdump` su Zeek.

### VPN non raggiunge VLAN interne

Verificare:

* rotta `10.8.0.0/24` su RouterOS;
* gateway `10.3.0.254`;
* regole firewall RouterOS;
* routing di ritorno;
* eventuali regole su Proxmox.

## Note operative

* Proxmox non è il router principale del laboratorio.
* RouterOS gestisce routing inter-VLAN.
* pfSense gestisce il traffico verso rete esterna simulata.
* OVS fornisce switching e mirroring verso Zeek.
* Le rotte devono essere coerenti tra VM, RouterOS e pfSense.
* Ogni modifica di rete dovrebbe essere verificata con ping, traceroute e tcpdump.

## Best practice

* mantenere chiaro il ruolo di ogni componente;
* documentare sempre gateway e subnet;
* aggiornare questo file se cambiano reti o rotte;
* verificare il routing dopo modifiche a Proxmox, RouterOS o pfSense;
* mantenere questo documento coerente con `network/routeros/`, `network/pfsense/` e `proxmox/network-bridges.md`.
