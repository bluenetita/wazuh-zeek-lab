# VLAN Configuration

Questo documento descrive la segmentazione VLAN utilizzata nel laboratorio.

## Obiettivo

La segmentazione VLAN ha lo scopo di separare logicamente i diversi componenti dell'infrastruttura, migliorando:

- isolamento tra sistemi;
- controllo del traffico;
- riduzione della superficie di attacco;
- capacità di monitoraggio;
- analisi degli scenari di attacco.

## VLAN definite

| VLAN | Nome | Ruolo | Sistemi |
|---:|---|---|---|
| 10 | Monitoring | Segmento dedicato ai sistemi di monitoraggio | ZeekVM, WazuhVM |
| 20 | Client | Segmento dedicato agli endpoint utente | ClientVM, WindowsVM |
| 30 | Server | Segmento dedicato ai server interni | ServerDB, VictimVM |

## VLAN 10 - Monitoring

La VLAN 10 contiene i sistemi dedicati al monitoraggio e alla detection.

Sistemi principali:

- ZeekVM;
- WazuhVM.

Ruolo:

- analisi del traffico di rete;
- raccolta eventi host-based;
- correlazione tra evidenze di rete e host;
- generazione alert.

## VLAN 20 - Client

La VLAN 20 contiene gli endpoint utente simulati.

Sistemi principali:

- ClientVM;
- WindowsVM.

Ruolo:

- simulazione di endpoint aziendali;
- generazione di traffico utente;
- target per alcuni scenari di attacco;
- host monitorati tramite Wazuh agent.

## VLAN 30 - Server

La VLAN 30 contiene i server interni.

Sistemi principali:

- ServerDB;
- VictimVM.

Ruolo:

- simulazione di servizi interni;
- server PostgreSQL;
- macchina vulnerabile per scenari controllati;
- target per reverse shell, privilege escalation e altri test.

## Rete esterna

La rete esterna non appartiene alle VLAN interne.

È simulata tramite `vmbr1` e contiene:

- AttackerVM / Kali Linux.

Questa rete rappresenta l'origine degli attacchi verso l'infrastruttura interna.

## Assegnazione logica

| Segmento | Bridge principale | Routing | Firewall |
|---|---|---|---|
| VLAN 10 | vmbr2 | RouterOS | pfSense verso esterno |
| VLAN 20 | vmbr2 | RouterOS | pfSense verso esterno |
| VLAN 30 | vmbr2 | RouterOS | pfSense verso esterno |
| External | vmbr1 | pfSense | pfSense |

## Note

- Le VLAN interne sono gestite su `vmbr2`, basato su Open vSwitch.
- Il routing inter-VLAN è gestito da RouterOS.
- Il traffico verso la rete esterna attraversa pfSense.
- Zeek riceve traffico tramite mirroring configurato su `vmbr2`.