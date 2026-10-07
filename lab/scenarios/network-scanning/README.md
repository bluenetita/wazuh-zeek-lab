# Network Scanning

Scenario di rilevamento di attività di scanning mediante script Zeek custom e regole Wazuh.

## Detector e soglie nello snapshot finale

| Detector | Soglia | Finestra |
|---|---:|---:|
| TCP address scan | 20 destinazioni per sorgente/porta | 60 s |
| TCP port scan | 100 porte | 60 s |
| UDP port scan | 50 porte | 60 s |
| ARP host scan | 20 target | 60 s |
| ICMP host scan | 2 target | 60 s |

Le soglie sono valori del laboratorio e non una baseline universale.

## Address scan

File aggiornato:

```text
blue-team/zeek/site/custom_scripts/scanning/address_scan.zeek
```

Lo script traccia, per TCP, le destinazioni contattate da una sorgente su una stessa porta e genera `address_scan` quando il numero di target raggiunge la soglia.

Durante le prove SSH il valore sperimentale `threshold=2` causava un falso positivo: A1 che contattava V1 e V2 sulla porta 22 veniva classificato anche come address scan. Lo snapshot finale mantiene `threshold=20`; dopo il cambiamento il test su due vittime non ha più prodotto `100918`.

## Correlazione con SSH

La regola `120936` collega scanning precedente e brute force SSH confermato dalla stessa sorgente. È intenzionalmente source-oriented: uno scan può coinvolgere più destinazioni e non sempre fornisce una singola vittima da confrontare.

Il tuning a 20 isola correttamente il test fan-out a due server, ma non costituisce una validazione completa dell'interazione simultanea tra uno scan reale e il fan-out SSH.

## Riproducibilità

Con soglia 20, contattare soltanto due host non è più sufficiente per riprodurre `100918`. Le prove di scanning devono essere coerenti con la soglia configurata e svolte esclusivamente nel cyber range autorizzato.
