# Troubleshooting

Questo documento raccoglie controlli e procedure utili per diagnosticare problemi nel cyber range.

## Obiettivo

L'obiettivo di questo file è fornire una guida rapida per verificare i componenti principali del laboratorio:

* Proxmox;
* Open vSwitch;
* pfSense;
* RouterOS;
* Zeek;
* Wazuh;
* AttackerVM / Kali;
* Client Linux;
* raccolta evidenze.

Il troubleshooting è organizzato per area, in modo da identificare rapidamente dove si trova il problema.

## Flusso generale da verificare

Prima di analizzare un singolo componente, verificare il percorso generale del traffico:

```text
AttackerVM / Kali
   |
   v
pfSense
   |
   v
RouterOS
   |
   v
Client Linux
```

Per la parte di monitoraggio:

```text
Traffico VLAN
   |
   v
Open vSwitch mirror
   |
   v
ZeekVM
   |
   v
Zeek logs
   |
   v
Wazuh Agent
   |
   v
Wazuh Manager
   |
   v
Alerts
```

## Checklist rapida

| Controllo            | Comando / Verifica                           |
| -------------------- | -------------------------------------------- |
| VM accese            | `qm list`                                    |
| Bridge presenti      | `ip link show`                               |
| OVS attivo           | `ovs-vsctl show`                             |
| Mirror OVS presente  | `ovs-vsctl list mirror`                      |
| RouterOS instrada    | `/ip route print detail`                     |
| pfSense instrada     | `netstat -rn`                                |
| Zeek riceve traffico | `tcpdump -i ens19.999 -n`                    |
| Zeek attivo          | `zeekctl status`                             |
| Wazuh Manager attivo | `systemctl status wazuh-manager`             |
| Wazuh Agent attivo   | `systemctl status wazuh-agent`               |
| Alert Wazuh generati | `tail -f /var/ossec/logs/alerts/alerts.json` |

## Proxmox

### Verificare VM attive

```bash
qm list
```

### Verificare configurazione di una VM

```bash
qm config <VM_ID>
```

Controllare:

* bridge assegnato;
* VLAN tag;
* interfacce di rete;
* stato della VM;
* ordine delle schede di rete.

### Verificare interfacce e bridge

```bash
ip link show
```

### Problema: una VM non comunica

Possibili cause:

* bridge errato;
* VLAN tag errato;
* gateway errato sulla VM;
* VM collegata al segmento sbagliato;
* firewall lato VM;
* regole RouterOS o pfSense.

Controlli:

```bash
qm config <VM_ID>
ip link show
```

## Open vSwitch

### Verificare configurazione OVS

```bash
ovs-vsctl show
```

### Verificare bridge OVS

```bash
ovs-vsctl list-br
```

### Verificare porte su `vmbr2`

```bash
ovs-vsctl list-ports vmbr2
```

### Verificare mirror

```bash
ovs-vsctl list mirror
```

### Verificare servizio mirror

```bash
systemctl status ovs-mirror.service
```

### Verificare log dello script mirror

```bash
tail -f /var/log/ovs-mirror.log
```

### Problema: il mirror OVS non esiste

Controllare:

```bash
systemctl status openvswitch-switch
systemctl status ovs-mirror.service
journalctl -u ovs-mirror.service
ovs-vsctl list mirror
```

Possibili cause:

* servizio `ovs-mirror.service` non abilitato;
* script non eseguibile;
* bridge `vmbr2` non presente;
* Open vSwitch non avviato;
* errore nello script `ovs-mirror.sh`.

Verificare permessi script:

```bash
ls -l /usr/local/bin/ovs-mirror.sh
```

Se necessario:

```bash
chmod +x /usr/local/bin/ovs-mirror.sh
```

## pfSense

### Verificare interfacce

Da shell pfSense:

```bash
ifconfig
```

### Verificare routing

```bash
netstat -rn
```

### Verificare regole firewall

```bash
pfctl -sr
```

### Problema: AttackerVM non raggiunge Client Linux

Controllare:

* interfacce pfSense;
* regole firewall;
* route verso RouterOS;
* NAT, se previsto;
* gateway lato rete esterna;
* gateway lato transito RouterOS.

Percorso atteso:

```text
AttackerVM
   |
   v
pfSense
   |
   v
RouterOS
   |
   v
VLAN Client
   |
   v
Client Linux
```

## RouterOS

### Verificare indirizzi IP

```text
/ip address print detail
```

### Verificare route

```text
/ip route print detail
```

### Verificare firewall

```text
/ip firewall filter print detail
```

### Verificare NAT

```text
/ip firewall nat print detail
```

### Problema: una VLAN non raggiunge un'altra VLAN

Controllare:

* gateway VLAN su RouterOS;
* subnet corretta sulla VM;
* route presenti;
* firewall filter;
* VLAN configurate su `ether2`;
* bridge Proxmox associato.

Gateway previsti:

| VLAN | Gateway     |
| ---: | ----------- |
|   10 | `10.3.10.1` |
|   20 | `10.3.20.1` |
|   30 | `10.3.30.1` |

### Problema: traffico verso l'esterno non funziona

Controllare default route:

```text
/ip route print detail
```

Default route attesa:

```text
0.0.0.0/0 -> 10.4.0.253
```

Controllare anche NAT:

```text
/ip firewall nat print detail
```

## Zeek

### Verificare stato Zeek

```bash
sudo /opt/zeek/bin/zeekctl status
```

### Verificare configurazione Zeek

```bash
sudo /opt/zeek/bin/zeekctl check
```

### Avviare o riavviare Zeek

```bash
sudo /opt/zeek/bin/zeekctl deploy
```

### Verificare interfacce

```bash
ip addr
ip link show ens19
ip link show ens19.999
```

### Verificare traffico ricevuto

```bash
sudo tcpdump -i ens19 -n
sudo tcpdump -i ens19.999 -n
```

### Verificare log standard

```bash
ls -lh /opt/zeek/logs/current/
```

### Verificare log custom

```bash
ls -lh /var/log/zeek-custom/
```

### Problema: Zeek non vede traffico

Controllare:

* mirror OVS presente;
* VLAN 999 configurata;
* interfaccia `ens19` attiva;
* interfaccia `ens19.999` attiva;
* modalità promiscua;
* configurazione `node.cfg`;
* servizio systemd per promisc;
* traffico realmente attraversa `vmbr2`.

Controlli:

```bash
ovs-vsctl list mirror
sudo tcpdump -i ens19.999 -n
sudo /opt/zeek/bin/zeekctl status
```

### Problema: i log custom non vengono generati

Controllare:

* script Zeek custom caricati;
* path `/var/log/zeek-custom/`;
* permessi directory;
* errori Zeek;
* stato `zeekctl`.

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl status
ls -lh /var/log/zeek-custom/
```

## Wazuh Manager

### Verificare stato Manager

```bash
sudo systemctl status wazuh-manager
```

### Verificare log Manager

```bash
sudo tail -f /var/ossec/logs/ossec.log
```

### Verificare alert

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

oppure:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.log
```

### Problema: Wazuh non genera alert

Controllare:

* Wazuh Manager attivo;
* agent connesso;
* log raccolti;
* decoder caricati;
* rules corrette;
* assenza di errori in `ossec.log`.

```bash
sudo grep -iE "error|decoder|rule" /var/ossec/logs/ossec.log
```

### Problema: decoder non funziona

Controllare:

* formato del log;
* campi JSON;
* regex decoder;
* nome del decoder;
* path del file decoder;
* riavvio del manager.

```bash
sudo systemctl restart wazuh-manager
sudo grep -i "decoder" /var/ossec/logs/ossec.log
```

### Problema: rule non scatta

Controllare:

* `if_sid`;
* `if_matched_sid`;
* `field`;
* `same_field`;
* `different_field`;
* `frequency`;
* `timeframe`;
* livello della rule;
* eventuali regole con livello `0`.

## Wazuh Agent

### Verificare stato Agent

```bash
sudo systemctl status wazuh-agent
```

### Verificare log Agent

```bash
sudo tail -f /var/ossec/logs/ossec.log
```

### Problema: agent non invia eventi

Controllare:

* connettività verso Wazuh Manager;
* configurazione `/var/ossec/etc/ossec.conf`;
* enrollment agent;
* servizio attivo;
* firewall;
* DNS;
* IP manager corretto.

### Agent ZeekVM

L'agent su ZeekVM deve leggere i log Zeek standard e custom.

Controllare configurazione localfile:

```bash
sudo grep -n "localfile" /var/ossec/etc/ossec.conf
```

Controllare permessi log custom:

```bash
ls -lh /var/log/zeek-custom/
```

I file devono essere leggibili dall'agent Wazuh.

## AttackerVM / Kali

### Verificare interfacce

```bash
ip -br addr
```

### Verificare routing

```bash
ip route
```

### Verificare DNS

```bash
cat /etc/resolv.conf
```

### Verificare NetworkManager

```bash
nmcli device status
nmcli connection show --active
```

### Problema: Kali non raggiunge il target

Controllare:

* IP di Kali;
* gateway `10.2.0.1`;
* route default;
* pfSense;
* RouterOS;
* firewall del target;
* VLAN Client.

```bash
ping <TARGET_IP>
traceroute <TARGET_IP>
```

## Client Linux

### Verificare IP

```bash
ip addr
```

### Verificare route

```bash
ip route
```

### Verificare gateway

```bash
ping 10.3.20.1
```

### Verificare Wazuh Agent

```bash
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
```

### Problema: Client Linux non comunica

Controllare:

* IP nella VLAN 20;
* gateway `10.3.20.1`;
* bridge Proxmox;
* VLAN tag;
* firewall locale;
* RouterOS;
* pfSense, se traffico esterno.

## Reverse Shell scenario

### Problema: nessun log Zeek

Controllare:

* traffico attraversa `vmbr2`;
* mirror OVS attivo;
* Zeek ascolta su `ens19.999`;
* log custom configurati;
* Zeek attivo.

```bash
ovs-vsctl list mirror
sudo tcpdump -i ens19.999 -n
sudo /opt/zeek/bin/zeekctl status
```

### Problema: nessun alert Wazuh

Controllare:

* log custom Zeek esistono;
* agent ZeekVM legge `/var/log/zeek-custom/`;
* decoder custom caricati;
* rules custom caricate;
* Wazuh Manager riavviato.

```bash
ls -lh /var/log/zeek-custom/
sudo grep -iE "error|decoder|rule" /var/ossec/logs/ossec.log
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

## Privilege Escalation scenario

### Problema: nessuna evidenza Wazuh

Controllare:

* agent installato sul Client Linux;
* agent connesso al Manager;
* log monitorati;
* FIM configurato, se usato;
* eventi realmente generati;
* rules Wazuh applicabili.

```bash
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

### Nota su Zeek

In questo scenario Zeek può avere visibilità limitata perché la Privilege Escalation avviene principalmente sul sistema target.

Zeek può vedere solo traffico di rete correlato, non attività locali come modifiche file, processi o cambi di privilegi.

## Evidence

### Prima di aggiungere evidenze

Controllare che i file siano:

* piccoli;
* sanificati;
* collegati allo scenario corretto;
* privi di credenziali;
* privi di payload;
* privi di exploit;
* privi di log completi.

### Controllo anti-segreti

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|cvv|iban|payload|exploit" evidence/
```

### Controllare diff

```bash
git diff evidence/
```

## Git e repository

### Vedere file modificati

```bash
git status
```

### Vedere differenze

```bash
git diff
```

### Vedere file ignorati

```bash
git status --ignored
```

### Controllo generale anti-segreti

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|cvv|iban|payload|exploit" .
```

## Errori comuni

| Problema                        | Possibile causa                                      |
| ------------------------------- | ---------------------------------------------------- |
| Zeek non vede traffico          | Mirror OVS assente o interfaccia errata              |
| Wazuh non genera alert          | Decoder/rules non caricati o log non raccolti        |
| Kali non raggiunge Client Linux | pfSense, RouterOS o gateway errato                   |
| Client Linux non comunica       | VLAN/gateway/bridge errato                           |
| Mirror sparisce dopo reboot     | `ovs-mirror.service` non abilitato                   |
| Nessun log custom Zeek          | Script custom non caricato o path errato             |
| Nessuna evidenza FIM            | Directory non monitorata da Wazuh                    |
| Alert non correlati             | Campi non coerenti o `same_field` non corrispondente |

## Best practice

* partire sempre dal livello rete prima di analizzare Zeek/Wazuh;
* verificare connettività base con `ping` e `traceroute`;
* verificare mirror OVS con `ovs-vsctl list mirror`;
* verificare traffico su Zeek con `tcpdump`;
* verificare agent e manager Wazuh;
* controllare sempre `ossec.log` dopo modifiche a decoder o rules;
* non caricare log grezzi completi nella repository;
* sanificare ogni evidenza prima del commit.

## Conclusione

Il troubleshooting del cyber range deve seguire un approccio a livelli:

```text
Virtualizzazione
   |
   v
Rete / routing / firewall
   |
   v
Mirroring OVS
   |
   v
Zeek
   |
   v
Wazuh
   |
   v
Scenari ed evidenze
```

Questo approccio aiuta a isolare rapidamente il componente responsabile del problema e a mantenere la documentazione coerente con l'architettura del laboratorio.
