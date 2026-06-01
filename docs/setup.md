# Setup

Questo documento descrive il setup generale del cyber range e indica l'ordine consigliato per configurare i componenti principali.

## Obiettivo

L'obiettivo di questo documento è fornire una guida ordinata alla configurazione dell'ambiente, senza includere credenziali, payload, exploit o file sensibili.

Il setup copre:

* infrastruttura Proxmox;
* bridge e Open vSwitch;
* pfSense;
* RouterOS;
* Zeek;
* Wazuh;
* VM interne;
* AttackerVM;
* scenari simulati;
* evidenze sanificate.

## Prerequisiti

Prima di procedere è necessario avere:

* host Proxmox funzionante;
* VM create nel laboratorio;
* bridge di rete configurati;
* pfSense installato;
* RouterOS installato;
* ZeekVM installata;
* WazuhVM installata;
* AttackerVM basata su Kali Linux;
* Client Linux configurato;
* eventuali VM aggiuntive come Client Windows, ServerDB e Victim Server.

## Ordine consigliato

L'ordine consigliato per configurare il laboratorio è:

```text
1. Proxmox
2. Bridge e Open vSwitch
3. pfSense
4. RouterOS
5. VM interne
6. Zeek
7. Wazuh
8. AttackerVM / Kali
9. Scenari
10. Evidenze
```

## 1. Proxmox

Proxmox ospita tutte le VM del laboratorio.

Documentazione correlata:

```text
proxmox/
```

File principali:

```text
proxmox/README.md
proxmox/vm-inventory.md
proxmox/network-bridges.md
proxmox/routing.md
proxmox/ovs-mirroring.md
```

Verifiche utili:

```bash
qm list
ip link show
```

## 2. Bridge e Open vSwitch

Open vSwitch viene usato per il bridge interno principale e per il mirror verso Zeek.

Documentazione correlata:

```text
proxmox/ovs/
proxmox/ovs-mirroring.md
proxmox/network-bridges.md
```

File principali:

```text
proxmox/ovs/ovs-mirror.sh
proxmox/ovs/ovs-mirror.service
```

Installazione dello script mirror:

```bash
sudo cp proxmox/ovs/ovs-mirror.sh /usr/local/bin/ovs-mirror.sh
sudo chmod +x /usr/local/bin/ovs-mirror.sh
```

Installazione del servizio systemd:

```bash
sudo cp proxmox/ovs/ovs-mirror.service /etc/systemd/system/ovs-mirror.service
sudo systemctl daemon-reload
sudo systemctl enable ovs-mirror.service
sudo systemctl start ovs-mirror.service
```

Verifiche:

```bash
ovs-vsctl show
ovs-vsctl list mirror
systemctl status ovs-mirror.service
tail -f /var/log/ovs-mirror.log
```

## 3. pfSense

pfSense separa la rete esterna simulata dalla rete interna.

Documentazione correlata:

```text
network/pfsense/
```

File principali:

```text
network/pfsense/README.md
network/pfsense/firewall-rules.md
network/pfsense/logging.md
network/pfsense/sanitized-config-notes.md
network/pfsense/config/
```

Ruolo principale:

```text
AttackerVM / Kali
   |
   v
pfSense
   |
   v
RouterOS
```

Verifiche da console o shell pfSense:

```bash
ifconfig
netstat -rn
pfctl -sr
```

## 4. RouterOS

RouterOS gestisce il routing inter-VLAN e la default route verso pfSense.

Documentazione correlata:

```text
network/routeros/
```

File principali:

```text
network/routeros/README.md
network/routeros/config/README.md
network/routeros/config/routeros-config-example.rsc
```

VLAN principali:

| VLAN | Ruolo      | Gateway     |
| ---: | ---------- | ----------- |
|   10 | Monitoring | `10.3.10.1` |
|   20 | Client     | `10.3.20.1` |
|   30 | Server     | `10.3.30.1` |

Default route:

```text
0.0.0.0/0 -> 10.4.0.253
```

Verifiche RouterOS:

```text
/ip address print detail
/ip route print detail
/ip firewall filter print detail
/ip firewall nat print detail
```

## 5. VM interne

Le VM interne sono documentate in:

```text
infrastructure/
```

Directory principali:

| Directory                        | Ruolo                                        |
| -------------------------------- | -------------------------------------------- |
| `infrastructure/client-linux/`   | Target principale degli scenari simulati     |
| `infrastructure/client-windows/` | Endpoint Windows interno                     |
| `infrastructure/server-db/`      | Server PostgreSQL interno                    |
| `infrastructure/victim-server/`  | Server vulnerabile basato su Metasploitable3 |

Il target principale degli scenari documentati è:

```text
Client Linux / ClientVM
```

Verifiche generiche su VM Linux:

```bash
ip addr
ip route
ping <GATEWAY_IP>
```

## 6. Zeek

Zeek riceve traffico mirrorato tramite OVS e genera log standard e custom.

Documentazione correlata:

```text
blue-team/zeek/
```

Directory principali:

```text
blue-team/zeek/netplan/
blue-team/zeek/systemd/
blue-team/zeek/logrotate/
blue-team/zeek/logs-samples/
```

Configurazioni importanti:

| Area       | Percorso                    |
| ---------- | --------------------------- |
| Netplan    | `blue-team/zeek/netplan/`   |
| systemd    | `blue-team/zeek/systemd/`   |
| logrotate  | `blue-team/zeek/logrotate/` |
| log custom | `/var/log/zeek-custom/`     |

Verifiche su ZeekVM:

```bash
ip addr
sudo tcpdump -i ens19 -n
sudo tcpdump -i ens19.999 -n
sudo /opt/zeek/bin/zeekctl status
ls -lh /var/log/zeek-custom/
```

## 7. Wazuh

Wazuh raccoglie eventi host-based e log custom Zeek.

Documentazione correlata:

```text
blue-team/wazuh/
```

Directory principali:

```text
blue-team/wazuh/manager/
blue-team/wazuh/agent-configs/
blue-team/wazuh/decoders/
blue-team/wazuh/rules/
blue-team/wazuh/integrations/
blue-team/wazuh/log-samples/
```

File importanti:

```text
blue-team/wazuh/agent-configs/zeek-agent-ossec.conf
blue-team/wazuh/decoders/zeek_decoders.xml
blue-team/wazuh/decoders/zeek_decoder_custom.xml
blue-team/wazuh/rules/001_zeek_rules.xml
blue-team/wazuh/rules/002_zeek_rules_custom.xml
blue-team/wazuh/rules/003_zeek_correlations.xml
```

Verifiche Wazuh Manager:

```bash
sudo systemctl status wazuh-manager
sudo tail -f /var/ossec/logs/ossec.log
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

Verifiche Wazuh Agent:

```bash
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
```

## 8. AttackerVM / Kali

AttackerVM è basata su Kali Linux e si trova nella rete esterna simulata.

Documentazione correlata:

```text
red-team/
red-team/attacker-kali/
red-team/attacker-kali/network/
```

Configurazione di rete documentata:

```text
red-team/attacker-kali/network/kali-network.conf
```

Verifiche su Kali:

```bash
ip -br addr
ip route
cat /etc/resolv.conf
nmcli device status
nmcli connection show --active
```

## 9. Scenari

Gli scenari simulati sono documentati in:

```text
scenarios/
```

Scenari documentati:

| Scenario             | Directory                         | Target       |
| -------------------- | --------------------------------- | ------------ |
| Reverse Shell        | `scenarios/reverse-shell/`        | Client Linux |
| Privilege Escalation | `scenarios/privilege-escalation/` | Client Linux |

La repository documenta solo scenari effettivamente simulati e validati.

## 10. Evidenze

Le evidenze sanificate sono documentate in:

```text
evidence/
```

Struttura principale:

```text
evidence/reverse-shell/zeek/
evidence/reverse-shell/wazuh/
evidence/privilege-escalation/wazuh/
```

Le evidenze devono essere:

* ridotte;
* sanificate;
* collegate allo scenario;
* prive di credenziali;
* prive di payload;
* prive di exploit;
* prive di log completi.

## Verifica end-to-end

Per verificare il funzionamento generale del laboratorio:

### Proxmox / OVS

```bash
ovs-vsctl show
ovs-vsctl list mirror
systemctl status ovs-mirror.service
```

### RouterOS

```text
/ip route print detail
/ip firewall filter print detail
```

### pfSense

```bash
netstat -rn
pfctl -sr
```

### ZeekVM

```bash
sudo tcpdump -i ens19.999 -n
sudo /opt/zeek/bin/zeekctl status
```

### Wazuh

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

### Client Linux

```bash
ip addr
ip route
sudo systemctl status wazuh-agent
```

### AttackerVM

```bash
ip route
ping <TARGET_IP>
```

## Controlli di sicurezza prima del commit

Prima di fare commit, controllare che non siano presenti dati sensibili:

```bash
grep -RniE "password|passwd|secret|token|private|key|credential|authd|client.keys|cvv|iban|payload|exploit" .
```

Controllare anche il diff:

```bash
git diff
```

Verificare i file ignorati:

```bash
git status --ignored
```

## File da non caricare

Non caricare nella repository:

* credenziali;
* token;
* chiavi private;
* certificati privati;
* payload;
* exploit;
* malware;
* reverse shell pronte all'uso;
* log completi;
* PCAP completi;
* dump database;
* backup VM;
* dischi virtuali;
* snapshot;
* file runtime.

## Note operative

Questo documento non sostituisce i README delle singole directory.

Serve come guida generale al setup e come indice operativo per capire in quale ordine configurare e verificare i componenti.

Per i dettagli specifici, consultare i file dedicati nelle rispettive directory.

## Checklist finale

| Controllo                       | Stato |
| ------------------------------- | ----- |
| Proxmox configurato             | TODO  |
| Bridge Proxmox presenti         | TODO  |
| Mirror OVS attivo               | TODO  |
| pfSense configurato             | TODO  |
| RouterOS configurato            | TODO  |
| Zeek riceve traffico            | TODO  |
| Wazuh Manager attivo            | TODO  |
| Agent Wazuh connessi            | TODO  |
| Client Linux raggiungibile      | TODO  |
| AttackerVM configurata          | TODO  |
| Scenari documentati             | TODO  |
| Evidenze sanificate             | TODO  |
| Controllo anti-segreti eseguito | TODO  |
