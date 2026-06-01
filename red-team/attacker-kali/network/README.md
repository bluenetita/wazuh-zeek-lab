# Kali Network Configuration

Questa directory contiene la documentazione relativa alla configurazione di rete della VM Kali utilizzata come `AttackerVM`.

## Obiettivo

La configurazione di rete di Kali è importante perché definisce il punto da cui vengono generati gli scenari red team controllati.

Nel laboratorio, `AttackerVM` si trova nella rete esterna simulata e comunica con il target interno attraversando pfSense e RouterOS.

## Posizione nella rete

| Campo          | Valore                |
| -------------- | --------------------- |
| VM             | `AttackerVM`          |
| Sistema        | Kali Linux            |
| Ruolo          | Macchina attaccante   |
| Segmento       | Rete esterna simulata |
| Bridge Proxmox | `vmbr1`               |

## Target principale

Nel laboratorio, il target principale degli scenari simulati è:

| Target                  | Ruolo                                    |
| ----------------------- | ---------------------------------------- |
| Client Linux / ClientVM | Endpoint Linux interno usato come target |

## Percorso verso il target

```text
AttackerVM / Kali
   |
   v
vmbr1
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

## File presenti

| File                          | Descrizione                                                      |
| ----------------------------- | ---------------------------------------------------------------- |
| `README.md`                   | Questo file                                                      |
| `kali-network-sanitized.conf` | Configurazione di rete sanificata o note operative della VM Kali |

## Informazioni da documentare

Nel file `kali-network-sanitized.conf` è possibile documentare:

* nome dell'interfaccia;
* indirizzo IP;
* subnet;
* gateway;
* DNS;
* bridge Proxmox associato;
* metodo di configurazione della rete;
* eventuali note sulla connettività verso pfSense.

## Metodo di configurazione

Kali può gestire la rete tramite NetworkManager oppure tramite file di configurazione tradizionali.

Comandi utili per identificare il metodo usato:

```bash
nmcli device status
nmcli connection show
```

Verificare eventuale configurazione tradizionale:

```bash
cat /etc/network/interfaces
```

## Relazione con pfSense

AttackerVM si trova sul lato esterno simulato del laboratorio.

Il traffico diretto verso la rete interna passa attraverso pfSense, che applica le regole firewall e controlla il traffico tra rete esterna e interna.

## Relazione con RouterOS

Dopo il passaggio attraverso pfSense, il traffico raggiunge RouterOS, che gestisce il routing verso le VLAN interne.

Nel caso degli scenari documentati, il target si trova nella VLAN Client.

## Relazione con Zeek

Zeek può osservare il traffico generato da AttackerVM quando questo attraversa le VLAN monitorate e il mirror OVS configurato su Proxmox.

Evidenze possibili:

* connessioni tra AttackerVM e Client Linux;
* durata delle connessioni;
* porte sorgente e destinazione;
* traffico TCP persistente;
* log custom relativi alla reverse shell.

## Relazione con Wazuh

Wazuh può osservare gli effetti degli scenari sul Client Linux e può generare alert a partire da:

* eventi host-based;
* log di sistema;
* eventi File Integrity Monitoring;
* log custom Zeek inoltrati al Wazuh Manager.

## Comandi utili

Verificare interfacce:

```bash
ip addr
```

Verificare routing:

```bash
ip route
```

Verificare DNS:

```bash
cat /etc/resolv.conf
```

Verificare stato NetworkManager:

```bash
nmcli device status
nmcli connection show
```

Verificare raggiungibilità di pfSense o del target:

```bash
ping <TARGET_IP>
```

Verificare percorso verso il target:

```bash
traceroute <TARGET_IP>
```

## Cosa versionare

È possibile versionare:

* configurazione di rete sanificata;
* note operative;
* output ridotti e sanificati;
* informazioni su IP, gateway e DNS se non sensibili;
* comandi di verifica innocui.

## Cosa non versionare

Non caricare:

* credenziali;
* token;
* chiavi private;
* file VPN sensibili;
* configurazioni contenenti segreti;
* output completi non sanificati;
* log completi;
* payload o file generati durante gli scenari.

## Note operative

Questa directory non deve contenere strumenti offensivi o payload.

Serve solo a documentare come la VM Kali è collegata alla rete del laboratorio e come raggiunge il target interno.

## Best practice

* mantenere la configurazione sanificata;
* aggiornare il file se cambia IP, gateway o bridge;
* non includere segreti;
* verificare sempre la connettività prima di eseguire scenari;
* mantenere questa documentazione coerente con `proxmox/network-bridges.md` e `red-team/attacker-kali/README.md`.
