# nftables

Questa directory contiene note e configurazioni relative all'utilizzo di `nftables` sull'host Proxmox.

## Obiettivo

`nftables` può essere utilizzato sull'host Proxmox per applicare regole di filtraggio a livello host.

Nel contesto del laboratorio, il controllo principale del traffico è affidato a:

* pfSense, per il traffico tra rete interna ed esterna;
* RouterOS, per il routing inter-VLAN;
* Open vSwitch, per switching, VLAN e mirroring.

`nftables` può essere usato come ulteriore livello di controllo sull'host Proxmox.

## Ruolo nell'infrastruttura

Nel laboratorio, `nftables` può influenzare:

* accesso amministrativo all'host Proxmox;
* traffico tra bridge;
* traffico generato o ricevuto dall'host;
* connettività delle VM;
* accesso remoto;
* traffico verso la rete esterna;
* funzionamento di servizi come OpenVPN;
* eventuale traffico usato per il monitoraggio.

Per questo motivo, le regole devono essere documentate e applicate con attenzione.

## Relazione con gli altri componenti

| Componente   | Ruolo                                      |
| ------------ | ------------------------------------------ |
| pfSense      | Firewall principale tra interno ed esterno |
| RouterOS     | Routing inter-VLAN                         |
| Open vSwitch | Switching virtuale, VLAN e mirroring       |
| nftables     | Filtraggio a livello host Proxmox          |
| Zeek         | Monitoraggio passivo del traffico          |
| Wazuh        | Monitoraggio host-based                    |

## File consigliati

Questa directory può contenere:

```text id="34ez2c"
nftables/
├── README.md
├── ruleset-current.nft
├── ruleset-sanitized.nft
└── notes.md
```

### `ruleset-current.nft`

Export del ruleset corrente.

Da usare solo localmente o in forma sanificata.

### `ruleset-sanitized.nft`

Versione ripulita del ruleset, adatta alla documentazione.

### `notes.md`

Note operative sulle regole applicate, problemi riscontrati e motivazioni delle scelte.

## Comandi utili

Visualizzare il ruleset corrente:

```bash
sudo nft list ruleset
```

Salvare il ruleset corrente in un file:

```bash id="h8ui4g"
sudo nft list ruleset > ruleset-current.nft
```

Verificare la sintassi di un file ruleset senza applicarlo:

```bash id="l1fxn8"
sudo nft -c -f ruleset-sanitized.nft
```

Applicare un ruleset:

```bash id="yhr5jz"
sudo nft -f ruleset-sanitized.nft
```

> Attenzione: applicare un ruleset errato può causare perdita di connettività verso l'host Proxmox.

## Procedura consigliata

Prima di modificare regole `nftables` sull'host Proxmox:

1. verificare di avere accesso alla console fisica o alla console Proxmox;
2. esportare il ruleset corrente;
3. creare una copia di backup;
4. testare la sintassi del nuovo ruleset;
5. applicare le modifiche in modo incrementale;
6. verificare la connettività;
7. verificare che le VM continuino a comunicare correttamente;
8. verificare che Zeek continui a ricevere traffico tramite mirroring;
9. documentare la modifica nella repository.

## Backup

Esempio di backup locale:

```bash id="hhxwv5"
sudo nft list ruleset > ruleset-backup-$(date +%Y%m%d-%H%M%S).nft
```

## Verifiche dopo una modifica

Dopo ogni modifica, verificare:

```bash id="zq8u3q"
sudo nft list ruleset
ip addr
ip route
ping <gateway>
```

Verificare anche la connettività delle VM:

```bash id="mzxm0g"
ping <ip-vm>
ping <gateway-vlan>
```

Verificare il traffico monitorato da Zeek:

```bash id="be1t55"
sudo tcpdump -i <interfaccia-zeek> -n
```

## Rischi principali

Una configurazione errata di `nftables` può causare:

* perdita dell'accesso remoto a Proxmox;
* blocco del traffico tra bridge;
* blocco del traffico delle VM;
* malfunzionamento di OpenVPN;
* traffico non più visibile a Zeek;
* blocco accidentale del traffico degli scenari di test.

## Cosa non caricare nella repository

Non caricare file contenenti:

* IP pubblici sensibili;
* credenziali;
* chiavi private;
* token;
* commenti con password o informazioni private;
* regole non comprese o non documentate;
* configurazioni complete non sanificate.

## Esempio di struttura sanificata

Esempio puramente documentale:

```nft
table inet filter {
    chain input {
        type filter hook input priority 0;
        policy accept;

        # Consentire traffico di management autorizzato
        # Regole reali omesse o sanificate
    }

    chain forward {
        type filter hook forward priority 0;
        policy accept;

        # Regole di forwarding sanificate
    }

    chain output {
        type filter hook output priority 0;
        policy accept;
    }
}
```

> Questo esempio non rappresenta necessariamente il ruleset reale del laboratorio.

## Note operative

Nel laboratorio, `nftables` deve essere considerato un livello aggiuntivo rispetto a pfSense e RouterOS.

La documentazione delle regole è utile per capire se eventuali problemi di connettività, routing o monitoraggio dipendono dal firewall host-level di Proxmox.
