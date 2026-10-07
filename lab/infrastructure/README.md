# Infrastructure

Questa directory documenta le VM interne del cyber range e il loro ruolo negli scenari.

## Sistemi principali

| Directory / Host | VLAN | Ruolo |
|---|---:|---|
| `client-linux/` / Client-Linux | 20 | endpoint Linux principale; reverse shell, Auditd, sorgente A1 nei test SSH |
| Client-Linux2 | 20 | clone di validazione SSH, sorgente A2 (`10.3.20.4`) |
| `client-windows/` | 20 | endpoint Windows interno |
| `server-db/` / ServerDB | 30 | server interno, servizio inventario, AppArmor, vittima V1 SSH |
| ServerDB2 | 30 | clone di validazione SSH, vittima V2 (`10.3.30.4`) |
| `victim-server/` | 30 | documentazione storica/legacy di un target precedente |

I cloni A2/V2 sono documentati nella topologia di validazione e non richiedono una copia completa delle stesse configurazioni nella repository.

## Osservabilità

Gli endpoint Linux e ServerDB inviano eventi al Wazuh Manager tramite agent. Il traffico di rete che attraversa il punto di mirror viene osservato da Zeek. Questa combinazione permette di verificare correlazioni cross-source.

## ServerDB

ServerDB ospita il servizio inventario usato per lo scenario vulnerabile/AppArmor e fornisce i log `sshd` necessari alla normalizzazione della destinazione nello scenario SSH.

## Client-Linux

Client-Linux è l'endpoint principale per reverse shell e telemetria Auditd ed è anche A1 nei test SSH multi-host. La quarantena RouterOS è stata verificata sul suo IP durante la campagna Active Response.
