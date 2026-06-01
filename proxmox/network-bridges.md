# Proxmox Network Bridges

Questo documento descrive i bridge di rete configurati sull'host Proxmox e il loro ruolo nel cyber range.

## Obiettivo

I bridge Proxmox permettono di collegare le macchine virtuali ai diversi segmenti di rete del laboratorio.

Nel progetto i bridge sono usati per separare:

* rete esterna simulata;
* rete interna con VLAN;
* collegamento RouterOS-pfSense;
* rete di test;
* traffico monitorato da Zeek.

## Bridge configurati

| Bridge       | Tipo                           | Ruolo                                                |
| ------------ | ------------------------------ | ---------------------------------------------------- |
| `vmbr1`      | Bridge / rete esterna simulata | Collegamento tra AttackerVM e pfSense                |
| `vmbr2`      | Open vSwitch bridge            | Rete interna principale, VLAN e mirroring verso Zeek |
| `vmbr3`      | Bridge di transito             | Collegamento tra RouterOS e pfSense                  |
| `vmbr4-test` | Bridge di test                 | Rete separata per test o esperimenti                 |

## vmbr1 - Rete esterna simulata

`vmbr1` rappresenta la rete esterna simulata del laboratorio.

È usato per collegare:

* AttackerVM / Kali Linux;
* interfaccia esterna di pfSense;
* eventuali altri sistemi esterni di test.

Ruolo logico:

```text
AttackerVM / Kali
   |
   v
vmbr1
   |
   v
pfSense
```

Questa rete simula il lato esterno rispetto all'infrastruttura aziendale interna.

## vmbr2 - Rete interna principale

`vmbr2` è il bridge interno principale del laboratorio.

È il bridge più importante per:

* traffico VLAN interno;
* collegamento delle VM interne;
* trunk verso RouterOS;
* mirroring del traffico verso Zeek;
* osservabilità network-based.

Su `vmbr2` transitano le VLAN principali:

| VLAN | Nome       | Ruolo                         |
| ---: | ---------- | ----------------------------- |
|   10 | Monitoring | ZeekVM, WazuhVM               |
|   20 | Client     | Client Linux, Client Windows  |
|   30 | Server     | ServerDB, VictimVM            |
|  999 | Mirror     | Traffico duplicato verso Zeek |

Schema logico:

```text
VM interne
   |
   v
vmbr2 / Open vSwitch
   |
   +--> RouterOS
   |
   +--> Mirror VLAN 999 verso Zeek
```

## vmbr3 - Collegamento RouterOS-pfSense

`vmbr3` viene usato come rete di transito tra RouterOS e pfSense.

Ruolo logico:

```text
RouterOS
   |
   v
vmbr3
   |
   v
pfSense
```

Questo segmento permette a RouterOS di inoltrare il traffico interno verso pfSense.

Il traffico verso la rete esterna segue quindi questo percorso:

```text
VM interna
   |
   v
vmbr2
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
Rete esterna simulata
```

## vmbr4-test - Rete di test

`vmbr4-test` è una rete separata usata per test o esperimenti.

Nel laboratorio è collegata a RouterOS tramite una terza interfaccia.

| Componente        | Collegamento  |
| ----------------- | ------------- |
| RouterOS `ether3` | `vmbr4-test`  |
| Rete associata    | `10.5.0.0/24` |
| Gateway RouterOS  | `10.5.0.1`    |

Questa rete può essere usata per testare configurazioni senza modificare i segmenti principali.

## Collegamenti principali delle VM

| VM             | Bridge / Segmento              | Ruolo                                     |
| -------------- | ------------------------------ | ----------------------------------------- |
| pfSense        | `vmbr1`, `vmbr3`               | Firewall tra rete esterna e interna       |
| RouterOS       | `vmbr2`, `vmbr3`, `vmbr4-test` | Routing inter-VLAN e uplink verso pfSense |
| ZeekVM         | VLAN Monitoring + VLAN mirror  | Monitoraggio traffico                     |
| WazuhVM        | VLAN Monitoring                | Wazuh Manager                             |
| Client Linux   | VLAN 20 su `vmbr2`             | Endpoint Linux                            |
| Client Windows | VLAN 20 su `vmbr2`             | Endpoint Windows                          |
| ServerDB       | VLAN 30 su `vmbr2`             | Server PostgreSQL                         |
| VictimVM       | VLAN 30 su `vmbr2`             | Target Metasploitable3                    |
| AttackerVM     | `vmbr1`                        | Kali / infrastruttura attaccante          |

## Relazione con Open vSwitch

`vmbr2` è gestito tramite Open vSwitch.

OVS viene usato per:

* trasportare traffico VLAN;
* supportare il trunk verso RouterOS;
* duplicare traffico verso Zeek;
* configurare il mirror delle VLAN 10, 20 e 30 verso VLAN 999.

La configurazione persistente del mirror OVS è documentata in:

```text
proxmox/ovs/
```

## Relazione con Zeek

Zeek riceve traffico duplicato da `vmbr2`.

Il traffico delle VLAN interne viene copiato verso la VLAN 999, che viene poi ricevuta dalla VM Zeek tramite interfaccia dedicata.

Schema:

```text
VLAN 10 / 20 / 30
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

## Relazione con RouterOS

RouterOS è il router principale delle VLAN interne.

Nel laboratorio:

| RouterOS Interface | Collegamento  | Ruolo                    |
| ------------------ | ------------- | ------------------------ |
| `ether1`           | verso pfSense | Uplink WAN RouterOS      |
| `ether2`           | `vmbr2`       | LAN / trunk VLAN interne |
| `ether3`           | `vmbr4-test`  | Rete di test             |

Le VLAN 10, 20 e 30 sono configurate su RouterOS sopra `ether2`.

## Relazione con pfSense

pfSense è collegato alla rete esterna simulata e alla rete di transito verso RouterOS.

| pfSense Interface | Collegamento | Ruolo                       |
| ----------------- | ------------ | --------------------------- |
| WAN               | `vmbr1`      | Rete esterna simulata       |
| LAN/Internal      | `vmbr3`      | Collegamento verso RouterOS |

## Verifiche utili su Proxmox

Visualizzare le interfacce:

```bash
ip link show
```

Visualizzare bridge OVS:

```bash
ovs-vsctl show
ovs-vsctl list-br
```

Visualizzare porte di un bridge:

```bash
ovs-vsctl list-ports vmbr2
```

Visualizzare mirror OVS:

```bash
ovs-vsctl list mirror
```

Visualizzare configurazione di una VM:

```bash
qm config <VM_ID>
```

## Troubleshooting

### Una VM non comunica

Verificare:

* bridge assegnato alla scheda di rete della VM;
* VLAN tag configurato;
* gateway della VM;
* route su RouterOS;
* regole firewall su RouterOS o pfSense.

### Zeek non vede traffico

Verificare:

* mirror OVS su `vmbr2`;
* VLAN 999;
* interfaccia Zeek `ens19` / `ens19.999`;
* modalità promiscua sulla VM Zeek;
* configurazione `node.cfg`;
* output di `tcpdump`.

### Traffico verso esterno non funziona

Verificare:

* route di default su RouterOS;
* collegamento RouterOS-pfSense su `vmbr3`;
* regole pfSense;
* NAT su RouterOS e/o pfSense;
* connettività su `vmbr1`.

## Note operative

* `vmbr2` è il bridge centrale per traffico interno e osservabilità.
* `vmbr1` rappresenta il lato esterno simulato.
* `vmbr3` collega RouterOS e pfSense.
* `vmbr4-test` è usato per esperimenti separati.
* La documentazione dei bridge deve rimanere coerente con RouterOS, pfSense, Zeek e l'inventario VM.

## Cosa non versionare

Non caricare:

* backup completi di Proxmox;
* file runtime;
* log completi;
* configurazioni contenenti credenziali;
* chiavi private;
* token;
* output non sanificati.

## Best practice

* documentare ogni bridge e il suo ruolo;
* mantenere aggiornata la tabella dei collegamenti VM;
* verificare le VLAN dopo modifiche alla rete;
* controllare il mirror OVS dopo reboot o modifiche Proxmox;
* mantenere coerenti `network-bridges.md`, `ovs-mirroring.md` e `proxmox/ovs/`.
