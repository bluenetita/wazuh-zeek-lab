# Open vSwitch on Proxmox

Questa directory contiene la documentazione e i file utilizzati per configurare il mirroring Open vSwitch su Proxmox.

## Obiettivo

Open vSwitch viene utilizzato nel laboratorio per gestire lo switching virtuale e per duplicare il traffico delle VLAN interne verso Zeek.

Il mirroring permette a Zeek di ricevere una copia del traffico di rete senza essere posizionato inline nel percorso del traffico.

## Ruolo nel laboratorio

OVS è utilizzato per:

* gestire bridge virtuali su Proxmox;
* trasportare traffico VLAN;
* collegare le VM ai segmenti corretti;
* duplicare traffico verso Zeek;
* rendere osservabile il traffico delle VLAN interne;
* supportare il monitoraggio network-based.

## Bridge principale

| Bridge  | Ruolo                                                           |
| ------- | --------------------------------------------------------------- |
| `vmbr2` | Bridge interno principale usato per VLAN e mirroring verso Zeek |

## VLAN monitorate

Lo script di mirror seleziona il traffico delle VLAN interne:

| VLAN | Ruolo      |
| ---: | ---------- |
|   10 | Monitoring |
|   20 | Client     |
|   30 | Server     |

Il traffico selezionato viene inviato verso:

| Output VLAN | Ruolo                                                        |
| ----------: | ------------------------------------------------------------ |
|         999 | VLAN usata per consegnare il traffico mirrorato alla VM Zeek |

## File presenti

| File                 | Descrizione                                   |
| -------------------- | --------------------------------------------- |
| `README.md`          | Questo file                                   |
| `ovs-mirror.sh`      | Script che crea o ricrea il mirror OVS        |
| `ovs-mirror.service` | Servizio systemd che esegue lo script al boot |

## Configurazione mirror

Lo script configura un mirror OVS con questi parametri:

| Parametro        | Valore                    |
| ---------------- | ------------------------- |
| Bridge           | `vmbr2`                   |
| Mirror name      | `zeek_mirror`             |
| VLAN selezionate | `10`, `20`, `30`          |
| Output VLAN      | `999`                     |
| Log file         | `/var/log/ovs-mirror.log` |

Schema logico:

```text
VLAN 10 / 20 / 30
   |
   v
vmbr2 / Open vSwitch
   |
   +--> traffico originale verso RouterOS / VM
   |
   +--> copia del traffico su VLAN 999 verso Zeek
```

## Relazione con Zeek

Zeek riceve il traffico mirrorato tramite interfaccia dedicata.

Nella VM Zeek sono configurate interfacce come:

```text
ens19
ens19.999
```

La VLAN `999` viene usata per trasportare il traffico duplicato verso Zeek.

## Relazione con RouterOS

RouterOS gestisce il routing delle VLAN interne.

OVS trasporta il traffico delle VLAN e permette di copiarlo verso Zeek prima o durante il passaggio verso RouterOS.

## Relazione con Wazuh

Wazuh non riceve direttamente traffico OVS, ma può ricevere alert derivati dai log generati da Zeek.

Flusso:

```text
OVS mirror
   |
   v
Zeek
   |
   v
Zeek custom logs
   |
   v
Wazuh Agent
   |
   v
Wazuh Manager
   |
   v
Alert
```

## Installazione

Copiare lo script sull'host Proxmox:

```bash
sudo cp proxmox/ovs/ovs-mirror.sh /usr/local/bin/ovs-mirror.sh
sudo chmod +x /usr/local/bin/ovs-mirror.sh
```

Copiare il servizio systemd:

```bash
sudo cp proxmox/ovs/ovs-mirror.service /etc/systemd/system/ovs-mirror.service
```

Ricaricare systemd:

```bash
sudo systemctl daemon-reload
```

Abilitare il servizio al boot:

```bash
sudo systemctl enable ovs-mirror.service
```

Avviare il servizio:

```bash
sudo systemctl start ovs-mirror.service
```

## Verifiche

Controllare stato del servizio:

```bash
sudo systemctl status ovs-mirror.service
```

Controllare log dello script:

```bash
sudo tail -f /var/log/ovs-mirror.log
```

Controllare configurazione OVS:

```bash
ovs-vsctl show
ovs-vsctl list mirror
```

Controllare bridge e porte:

```bash
ovs-vsctl list-br
ovs-vsctl list-ports vmbr2
```

Verificare traffico sulla VM Zeek:

```bash
sudo tcpdump -i ens19 -n
sudo tcpdump -i ens19.999 -n
```

## Troubleshooting

### Il mirror non viene creato

Verificare che OVS sia attivo:

```bash
sudo systemctl status openvswitch-switch
```

Verificare che il bridge esista:

```bash
ovs-vsctl br-exists vmbr2
```

Verificare manualmente i mirror:

```bash
ovs-vsctl list mirror
```

### Zeek non riceve traffico

Verificare:

* che il servizio `ovs-mirror.service` sia attivo;
* che il mirror sia presente in OVS;
* che la VLAN 999 arrivi alla VM Zeek;
* che `ens19` e `ens19.999` siano attive;
* che le interfacce Zeek siano in modalità promiscua;
* che `node.cfg` usi l'interfaccia corretta.

### Dopo reboot il mirror sparisce

Verificare che il servizio sia abilitato:

```bash
sudo systemctl is-enabled ovs-mirror.service
```

Controllare i log:

```bash
journalctl -u ovs-mirror.service
sudo cat /var/log/ovs-mirror.log
```

## Cosa versionare

È possibile versionare:

* script di configurazione OVS;
* unit systemd;
* documentazione;
* comandi di verifica;
* output sanificati;
* note operative.

## Cosa non versionare

Non caricare:

* log completi non sanificati;
* configurazioni non comprese;
* credenziali;
* token;
* chiavi private;
* script distruttivi non testati;
* output contenenti informazioni sensibili.

## Best practice

* verificare il mirror dopo ogni reboot;
* mantenere lo script semplice e leggibile;
* usare variabili per bridge, VLAN e nome mirror;
* controllare sempre che Zeek riceva traffico con `tcpdump`;
* mantenere questa documentazione allineata con `blue-team/zeek/`;
* non modificare OVS senza prima salvare la configurazione funzionante.
