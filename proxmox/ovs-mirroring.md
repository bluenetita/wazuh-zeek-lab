# OVS Mirroring

Questo documento descrive il mirroring Open vSwitch configurato su Proxmox per inviare una copia del traffico di rete verso Zeek.

## Obiettivo

Il mirroring OVS permette a Zeek di osservare il traffico delle VLAN interne senza essere posizionato inline nel percorso di rete.

In questo modo Zeek riceve una copia del traffico e può generare log network-based senza modificare o bloccare il traffico originale.

## Ruolo nel laboratorio

Nel laboratorio, il mirroring viene utilizzato per fornire visibilità sul traffico generato dalle VM interne.

Zeek osserva il traffico duplicato e produce log come:

* `conn.log`;
* `dns.log`;
* `http.log`;
* `tls.log`;
* `weird.log`;
* log custom per scenari come reverse shell e download sospetti.

## Bridge coinvolto

Il mirror è configurato sul bridge:

```text
vmbr2
```

`vmbr2` è il bridge interno principale del laboratorio ed è usato per:

* VLAN interne;
* traffico client-server;
* collegamento verso RouterOS;
* osservabilità network-based;
* consegna del traffico mirrorato a Zeek.

## VLAN monitorate

Il mirror seleziona il traffico delle VLAN principali:

| VLAN | Ruolo      |
| ---: | ---------- |
|   10 | Monitoring |
|   20 | Client     |
|   30 | Server     |

Queste VLAN contengono i principali sistemi osservati dal laboratorio.

## Output del mirror

Il traffico duplicato viene inviato sulla VLAN:

| VLAN | Ruolo                  |
| ---: | ---------------------- |
|  999 | VLAN mirror verso Zeek |

La VM Zeek riceve il traffico mirrorato tramite interfacce dedicate, ad esempio:

```text
ens19
ens19.999
```

## Schema logico

```text
VLAN 10 / 20 / 30
   |
   v
vmbr2 / Open vSwitch
   |
   +--> traffico originale verso RouterOS / VM interne
   |
   +--> copia del traffico su VLAN 999
           |
           v
        ZeekVM
```

## Configurazione implementata

La configurazione persistente del mirror è documentata in:

```text
proxmox/ovs/
```

File coinvolti:

| File                             | Descrizione                                   |
| -------------------------------- | --------------------------------------------- |
| `proxmox/ovs/ovs-mirror.sh`      | Script che crea o ricrea il mirror OVS        |
| `proxmox/ovs/ovs-mirror.service` | Servizio systemd che esegue lo script al boot |
| `proxmox/ovs/README.md`          | Documentazione di installazione e verifica    |

## Parametri del mirror

Lo script usa i seguenti parametri:

| Parametro        | Valore                    |
| ---------------- | ------------------------- |
| Bridge           | `vmbr2`                   |
| Mirror name      | `zeek_mirror`             |
| VLAN selezionate | `10`, `20`, `30`          |
| Output VLAN      | `999`                     |
| Log file         | `/var/log/ovs-mirror.log` |

Comando OVS usato nello script:

```bash
ovs-vsctl -- --id=@m create mirror name="zeek_mirror" select-all=true select-vlan=10,20,30 output-vlan="999" -- set bridge "vmbr2" mirrors=@m
```

## Persistenza

La configurazione del mirror può non essere persistente dopo reboot o restart dei servizi di rete.

Per questo motivo viene usato un servizio `systemd`:

```text
ovs-mirror.service
```

Il servizio esegue:

```text
/usr/local/bin/ovs-mirror.sh
```

e ricrea il mirror quando necessario.

## Relazione con Zeek

Zeek deve ricevere il traffico mirrorato sull'interfaccia corretta.

Nel laboratorio la VM Zeek usa:

| Interfaccia | Ruolo                                   |
| ----------- | --------------------------------------- |
| `ens19`     | Interfaccia di monitoring               |
| `ens19.999` | Interfaccia VLAN per traffico mirrorato |

La configurazione Netplan della VM Zeek è documentata in:

```text
blue-team/zeek/netplan/
```

I servizi systemd della VM Zeek abilitano la modalità promiscua su:

```text
ens19
ens19.999
```

Documentazione correlata:

```text
blue-team/zeek/systemd/
```

## Relazione con RouterOS

RouterOS gestisce il routing delle VLAN interne.

Il mirror OVS copia il traffico senza sostituire il ruolo di RouterOS.

RouterOS continua a gestire:

* gateway VLAN;
* routing inter-VLAN;
* default route verso pfSense;
* firewall inter-VLAN;
* NAT verso pfSense, se configurato.

## Relazione con Wazuh

Wazuh non riceve direttamente il traffico mirrorato.

Il flusso è:

```text
OVS mirror
   |
   v
Zeek
   |
   v
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

## Verifiche su Proxmox

Controllare configurazione OVS:

```bash
ovs-vsctl show
```

Controllare mirror configurati:

```bash
ovs-vsctl list mirror
```

Controllare bridge:

```bash
ovs-vsctl list-br
```

Controllare porte su `vmbr2`:

```bash
ovs-vsctl list-ports vmbr2
```

Controllare servizio systemd:

```bash
systemctl status ovs-mirror.service
```

Controllare log dello script:

```bash
tail -f /var/log/ovs-mirror.log
```

## Verifiche su ZeekVM

Controllare che le interfacce siano presenti:

```bash
ip link show ens19
ip link show ens19.999
```

Controllare traffico ricevuto:

```bash
sudo tcpdump -i ens19 -n
sudo tcpdump -i ens19.999 -n
```

Controllare traffico con tag VLAN:

```bash
sudo tcpdump -i ens19 -e -n
sudo tcpdump -i ens19.999 -e -n
```

Controllare Zeek:

```bash
sudo /opt/zeek/bin/zeekctl status
sudo /opt/zeek/bin/zeekctl check
```

## Troubleshooting

### Il mirror non compare in OVS

Verificare:

* che Open vSwitch sia attivo;
* che `vmbr2` esista;
* che lo script sia eseguibile;
* che il servizio systemd sia attivo;
* eventuali errori in `/var/log/ovs-mirror.log`.

Comandi utili:

```bash
systemctl status openvswitch-switch
systemctl status ovs-mirror.service
journalctl -u ovs-mirror.service
ovs-vsctl list mirror
```

### Zeek non riceve traffico

Verificare:

* presenza del mirror su Proxmox;
* VLAN 999;
* configurazione Netplan di Zeek;
* modalità promiscua su `ens19` e `ens19.999`;
* interfaccia configurata in `node.cfg`;
* output di `tcpdump`.

### Il mirror sparisce dopo reboot

Verificare che il servizio sia abilitato:

```bash
systemctl is-enabled ovs-mirror.service
```

Controllare log:

```bash
journalctl -u ovs-mirror.service
cat /var/log/ovs-mirror.log
```

## Limiti

Il mirroring permette a Zeek di osservare il traffico duplicato, ma non garantisce visibilità su:

* traffico che non attraversa `vmbr2`;
* traffico non incluso nelle VLAN selezionate;
* contenuto cifrato;
* eventi locali sugli host;
* processi o modifiche filesystem.

Per gli eventi host-based è necessario usare Wazuh.

## Note operative

* Il mirror è configurato per VLAN 10, 20 e 30.
* La VLAN 999 è usata come destinazione per il traffico mirrorato.
* Zeek deve ascoltare sull'interfaccia corretta.
* Dopo modifiche di rete su Proxmox, verificare sempre il mirror.
* Dopo modifiche su Zeek, verificare sempre `tcpdump` e `zeekctl status`.

## Best practice

* mantenere il mirror documentato e versionato;
* verificare il mirror dopo ogni reboot;
* mantenere allineati `proxmox/ovs-mirroring.md` e `proxmox/ovs/`;
* testare il traffico con `tcpdump`;
* evitare di modificare OVS senza backup della configurazione funzionante;
* non caricare log completi o output non sanificati nella repository.
