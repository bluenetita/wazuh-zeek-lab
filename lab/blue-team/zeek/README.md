# Zeek

Zeek è il sensore Network Security Monitoring del cyber range. Riceve il traffico mirrorato da Open vSwitch e produce sia log standard sia log custom inviati a Wazuh.

## Punto di osservazione

```text
VLAN 10 / 20 / 30
        |
   OVS mirror
        |
     VLAN 999
        |
     ZeekVM
        |
   Wazuh Agent
```

L'interfaccia di mirror usata nel laboratorio è `ens19.999`.

## File principali

| File | Funzione |
|---|---|
| `site/local.zeek` | JSON logging e caricamento degli script custom |
| `site/custom_scripts/reverse_shell/reverse_shell_movement.zeek` | movement detector v2 |
| `site/custom_scripts/scanning/address_scan.zeek` | TCP address scan |
| `site/custom_scripts/ssh_bruteforce/ssh_bruteforce.zeek` | rilevamento SSH per coppia sorgente/destinazione |

Gli altri script già presenti nel repository (`reverse_shell.zeek`, malware/download, scanning loader, logging, exfiltration e altri detector) vanno conservati.

## Log custom

I log custom sono scritti sotto `/var/log/zeek-custom/`. Quelli più rilevanti sono:

```text
possible_malware.log
reverse_shell_live.log
reverse_shell_movement.log
reverse_shell_final.log
scanning.log
ssh_bruteforce.log
```

Il movement detector v2 mantiene anche un log diagnostico dedicato per le verifiche sperimentali.

## Reverse shell movement v2

Il detector considera TCP verso destinazioni non appartenenti alle subnet interne escluse e applica la logica principale:

```text
duration >= 30 s
orig_pkts > 10
resp_pkts > 10
```

Le vecchie medie di dimensione pacchetto sono mantenute solo come diagnostica. La connessione viene rivalutata periodicamente e alla ricezione di pacchetti; una stessa connessione emette al massimo un evento movement.

I contatori packet-based possono essere influenzati da copie del mirror o ritrasmissioni: l'euristica non equivale a un'identificazione certa di una reverse shell.

## SSH brute force

Lo script SSH mantiene lo stato per:

```text
[src_ip, dest_ip, dest_port]
```

Quando Zeek dispone di un esito di autenticazione inferito, usa il relativo percorso. Quando l'esito non è disponibile sul traffico cifrato, il fallback conta connessioni SSH ripetute e produce un candidato con, per esempio:

```text
failed_connections = 0
unknown_connections = 5
auth_attempts = 0
detection_reason = repeated_ssh_connections_unknown_auth
```

Questo **non** significa che Zeek abbia osservato cinque password errate. La conferma dei fallimenti proviene dai log `sshd` raccolti da Wazuh.

## Scanning

Valori presenti nello snapshot finale:

| Detector | Soglia | Finestra |
|---|---:|---:|
| TCP address scan | 20 target | 60 s |
| TCP port scan | 100 porte | 60 s |
| UDP port scan | 50 porte | 60 s |
| ARP host scan | 20 target | 60 s |
| ICMP host scan | 2 target | 60 s |

La soglia di `address_scan` è stata riportata da 2 a 20 perché il valore di test classificava anche il semplice contatto SSH verso due server come scan. Si tratta di tuning del laboratorio, non di una baseline universale.

## Qualità della cattura

Nelle verifiche su `ens19.999` sono stati osservati GRO `off`, GSO `on` e LRO `off [fixed]`. La repository non include una unit persistente non verificata per forzare tali valori dopo reboot.

`ignore_checksums=T` è presente nella configurazione di laboratorio. Va rivalutato in un deployment differente.

## Verifiche operative

```bash
sudo /opt/zeek/bin/zeekctl check
sudo /opt/zeek/bin/zeekctl status
```

Applicare `zeekctl deploy` solo quando si vuole effettivamente ricaricare il sensore; un deploy può azzerare stato runtime utile ai test.

## Limiti

Zeek non vede direttamente processi, comandi locali, modifiche al filesystem o il contenuto applicativo cifrato. Per questi aspetti il progetto combina Zeek con Wazuh, Auditd e, negli scenari di mitigazione, AppArmor.
