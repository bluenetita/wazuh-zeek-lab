# Zeek systemd Services

Questa directory contiene i servizi `systemd` utilizzati per configurare l'interfaccia di monitoraggio e avviare Zeek automaticamente.

## Obiettivo

Nel laboratorio, Zeek riceve traffico duplicato tramite interfaccia dedicata.

Per permettere a Zeek di osservare correttamente il traffico, alcune interfacce vengono configurate in modalità promiscua al boot.

Questa directory documenta i servizi usati per:

* abilitare la modalità promiscua sull'interfaccia fisica/virtuale di monitoraggio;
* abilitare la modalità promiscua su una VLAN dedicata;
* avviare Zeek tramite `zeekctl`.

## File presenti

| File                     | Descrizione                                                     |
| ------------------------ | --------------------------------------------------------------- |
| `bridge-promisc.service` | Abilita la modalità promiscua sull'interfaccia `ens19`          |
| `vlan-promisc.service`   | Abilita la modalità promiscua sull'interfaccia VLAN `ens19.999` |
| `zeek.service`           | Avvia Zeek tramite `/opt/zeek/bin/zeekctl deploy`               |

## Interfacce coinvolte

| Interfaccia    | Ruolo                                                       |
| -------------- | ----------------------------------------------------------- |
| `ens19`        | Interfaccia di monitoraggio collegata al traffico duplicato |
| `ens19.999`    | Interfaccia VLAN usata per il traffico monitorato           |
| Zeek interface | Interfaccia configurata in `node.cfg`                       |

## bridge-promisc.service

Il servizio `bridge-promisc.service` abilita la modalità promiscua su `ens19`.

Questo permette all'interfaccia di ricevere traffico non necessariamente destinato al suo MAC address, condizione utile quando Zeek analizza traffico duplicato o mirrorato.

Comando principale:

```bash
/usr/sbin/ip link set dev ens19 up promisc on
```

## vlan-promisc.service

Il servizio `vlan-promisc.service` porta su l'interfaccia VLAN `ens19.999` e abilita la modalità promiscua.

Comandi principali:

```bash
/sbin/ip link set ens19.999 up
/sbin/ip link set ens19.999 promisc on
```

## zeek.service

Il servizio `zeek.service` avvia Zeek usando `zeekctl`.

Comandi principali:

```bash
/opt/zeek/bin/zeekctl deploy
/opt/zeek/bin/zeekctl stop
/opt/zeek/bin/zeekctl restart
```

## Installazione servizi

Copiare i file nella directory systemd:

```bash
sudo cp bridge-promisc.service /etc/systemd/system/
sudo cp vlan-promisc.service /etc/systemd/system/
sudo cp zeek.service /etc/systemd/system/
```

Ricaricare systemd:

```bash
sudo systemctl daemon-reload
```

Abilitare i servizi al boot:

```bash
sudo systemctl enable bridge-promisc.service
sudo systemctl enable vlan-promisc.service
sudo systemctl enable zeek.service
```

Avviare i servizi:

```bash
sudo systemctl start bridge-promisc.service
sudo systemctl start vlan-promisc.service
sudo systemctl start zeek.service
```

## Verifiche

Controllare lo stato dei servizi:

```bash
sudo systemctl status bridge-promisc.service
sudo systemctl status vlan-promisc.service
sudo systemctl status zeek.service
```

Verificare la modalità promiscua:

```bash
ip link show ens19
ip link show ens19.999
```

Verificare Zeek:

```bash
sudo /opt/zeek/bin/zeekctl status
sudo /opt/zeek/bin/zeekctl check
```

Verificare traffico ricevuto:

```bash
sudo tcpdump -i ens19 -n
sudo tcpdump -i ens19.999 -n
```

## Note operative

* `ens19` deve corrispondere all'interfaccia di monitoraggio reale della VM Zeek.
* `ens19.999` deve esistere prima dell'avvio del servizio `vlan-promisc.service`.
* Se il nome dell'interfaccia cambia, i servizi devono essere aggiornati.
* Dopo modifiche ai file `.service`, eseguire sempre `sudo systemctl daemon-reload`.
* Se Zeek non genera log, verificare prima che l'interfaccia corretta riceva traffico con `tcpdump`.

## Relazione con Zeek

Questi servizi sono necessari per garantire che Zeek possa ricevere traffico sull'interfaccia configurata in `node.cfg`.

La configurazione effettiva dell'interfaccia usata da Zeek deve essere controllata in:

```text
blue-team/zeek/etc/node.cfg
```

## Best practice

* mantenere i servizi versionati nella repository;
* documentare eventuali modifiche ai nomi delle interfacce;
* verificare lo stato dei servizi dopo ogni reboot;
* usare `tcpdump` per validare la ricezione del traffico;
* controllare `zeekctl status` dopo l'avvio automatico.
