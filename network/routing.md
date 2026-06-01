# Routing

Questo documento descrive il routing logico dell'infrastruttura simulata.

## Obiettivo

Il routing consente la comunicazione controllata tra i diversi segmenti della rete interna e la rete esterna simulata.

L'infrastruttura è suddivisa in VLAN, ciascuna dedicata a una specifica categoria di sistemi:

* VLAN 10 - Monitoring;
* VLAN 20 - Client;
* VLAN 30 - Server.

Il routing tra le VLAN interne è gestito da RouterOS, mentre il traffico tra rete interna e rete esterna è controllato da pfSense.

## Componenti coinvolti

| Componente | Ruolo                                            |
| ---------- | ------------------------------------------------ |
| RouterOS   | Gestisce il routing inter-VLAN                   |
| pfSense    | Gestisce il traffico tra rete interna ed esterna |
| vmbr2      | Open vSwitch principale per le VLAN interne      |
| vmbr3      | Bridge di collegamento tra RouterOS e pfSense    |
| vmbr1      | Bridge usato per simulare la rete esterna        |
| AttackerVM | Macchina Kali Linux nella rete esterna simulata  |

## Segmenti di rete

| Segmento   | VLAN | Ruolo                    | Sistemi principali      |
| ---------- | ---: | ------------------------ | ----------------------- |
| Monitoring |   10 | Monitoraggio e detection | ZeekVM, WazuhVM         |
| Client     |   20 | Endpoint interni         | ClientVM, WindowsVM     |
| Server     |   30 | Server interni           | ServerDB, VictimVM      |
| External   |    - | Rete esterna simulata    | AttackerVM / Kali Linux |

## Routing inter-VLAN

Il routing tra le VLAN interne è gestito da RouterOS.

RouterOS espone interfacce VLAN dedicate per ciascun segmento di rete e agisce come gateway logico per le macchine appartenenti alle rispettive VLAN.

| VLAN | Nome       | Gateway                        |
| ---: | ---------- | ------------------------------ |
|   10 | Monitoring | RouterOS - interfaccia VLAN 10 |
|   20 | Client     | RouterOS - interfaccia VLAN 20 |
|   30 | Server     | RouterOS - interfaccia VLAN 30 |

> Nota: inserire gli indirizzi IP reali o sanificati dei gateway quando disponibili.

Esempio:

| VLAN | Nome       | Gateway di esempio |
| ---: | ---------- | ------------------ |
|   10 | Monitoring | 192.168.10.1       |
|   20 | Client     | 192.168.20.1       |
|   30 | Server     | 192.168.30.1       |

## Traffico verso la rete esterna

Il traffico diretto verso la rete esterna segue questo percorso logico:

```text
VM interna
   |
   v
vmbr2 / Open vSwitch
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
Rete esterna simulata / AttackerVM
```

In questo modello:

1. le VM interne sono collegate a `vmbr2`;
2. `vmbr2` gestisce la connettività Layer 2 e le VLAN;
3. RouterOS effettua il routing tra VLAN;
4. il traffico destinato all'esterno viene inoltrato verso pfSense tramite `vmbr3`;
5. pfSense applica le regole firewall;
6. il traffico raggiunge la rete esterna simulata tramite `vmbr1`.

## Ruolo di RouterOS

RouterOS è il componente responsabile del routing tra i segmenti interni.

Le sue funzioni principali sono:

* gestione delle interfacce VLAN;
* assegnazione dei gateway per le VLAN interne;
* routing tra Monitoring, Client e Server;
* inoltro del traffico verso pfSense;
* separazione logica dei segmenti di rete.

RouterOS permette quindi la comunicazione controllata tra:

* VLAN 10 e VLAN 20;
* VLAN 10 e VLAN 30;
* VLAN 20 e VLAN 30;
* VLAN interne e pfSense.

## Ruolo di pfSense

pfSense è il firewall dell'infrastruttura.

Il suo ruolo è controllare il traffico tra la rete interna e la rete esterna simulata.

pfSense gestisce:

* traffico in uscita verso la rete esterna;
* traffico in ingresso dalla rete esterna;
* eventuali regole NAT;
* regole firewall;
* logging degli eventi di rete;
* separazione tra infrastruttura aziendale simulata e rete attaccante.

## Flussi principali

| Origine          | Destinazione    | Percorso logico                      |
| ---------------- | --------------- | ------------------------------------ |
| ClientVM         | ServerDB        | VLAN 20 → RouterOS → VLAN 30         |
| WindowsVM        | VictimVM        | VLAN 20 → RouterOS → VLAN 30         |
| ZeekVM / WazuhVM | Host monitorati | VLAN 10 → RouterOS → VLAN 20/30      |
| ClientVM         | Rete esterna    | VLAN 20 → RouterOS → pfSense → vmbr1 |
| VictimVM         | AttackerVM      | VLAN 30 → RouterOS → pfSense → vmbr1 |
| AttackerVM       | VictimVM        | vmbr1 → pfSense → RouterOS → VLAN 30 |

## Relazione con il monitoraggio

Il routing è importante anche per il monitoraggio.

Zeek osserva il traffico duplicato tramite mirroring configurato su `vmbr2`.

Questo significa che Zeek può analizzare il traffico che attraversa il punto di osservazione configurato, ma non può vedere traffico che non passa da quel punto o che non viene incluso nel mirror.

Wazuh, invece, osserva gli eventi direttamente dagli host monitorati tramite agent.

Questa distinzione è importante perché:

* Zeek fornisce visibilità sui flussi di rete;
* Wazuh fornisce visibilità sulle attività locali degli host;
* la correlazione tra i due strumenti migliora la detection.

## Considerazioni di sicurezza

Il routing inter-VLAN deve essere controllato per evitare comunicazioni non necessarie tra segmenti.

Regole consigliate a livello logico:

* limitare il traffico dai client ai soli servizi necessari;
* limitare l'accesso ai server interni;
* controllare il traffico proveniente dalla rete esterna;
* consentire solo le comunicazioni necessarie verso i sistemi di monitoraggio;
* registrare eventi rilevanti su pfSense e Wazuh;
* verificare che il traffico degli scenari passi dal punto osservato da Zeek.

## Troubleshooting

### Verifica connettività da Linux

```bash
ip addr
ip route
ping <gateway>
traceroute <destinazione>
```

### Verifica routing su RouterOS

```text
/ip address print
/interface vlan print
/ip route print
```

### Verifica su pfSense

Da interfaccia web pfSense:

```text
Diagnostics > Routes
Diagnostics > Ping
Diagnostics > Packet Capture
Status > System Logs > Firewall
```

## Note

Gli indirizzi IP reali possono essere aggiunti in una fase successiva, preferibilmente usando indirizzi privati o valori sanificati.

Non inserire in questo file:

* password;
* chiavi private;
* token;
* IP pubblici sensibili;
* configurazioni esportate senza sanificazione.
