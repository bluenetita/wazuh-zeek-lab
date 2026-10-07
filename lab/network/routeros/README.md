# RouterOS

RouterOS è il router inter-VLAN del cyber range e, nello scenario di risposta automatica, anche il punto di enforcement della quarantena Wazuh.

## Ruolo di rete

| Interfaccia | Ruolo | Rete |
|---|---|---|
| `ether1` | uplink verso pfSense | `10.4.0.0/24` |
| `ether2` | trunk/LAN verso le VLAN interne | `10.3.0.0/16` |
| `ether3` | rete di test | `10.5.0.0/24` |
| `vlan10` | Monitoring | `10.3.10.0/24` |
| `vlan20` | Client | `10.3.20.0/24` |
| `vlan30` | Server | `10.3.30.0/24` |

Gateway documentati nel laboratorio:

```text
vlan10  10.3.10.1/24
vlan20  10.3.20.1/24
vlan30  10.3.30.1/24
```

RouterOS inoltra il traffico esterno verso pfSense e mantiene anche la rotta della rete VPN documentata nella configurazione del laboratorio. Il masquerade verso l'uplink può modificare l'IP sorgente osservato da pfSense.

I file storici di interfacce, VLAN, routing e firewall già presenti in questa directory restano parte della documentazione e non vengono sostituiti da questo README.

## Quarantena Wazuh

L'Active Response usa una address-list denominata `Quarantine`. Lo script pubblico è:

```text
blue-team/wazuh/active-response/routeros_quarantine.py
```

Il modello di configurazione è:

```text
blue-team/wazuh/active-response/routeros.conf.example
```

Il file contiene soltanto placeholder: chiave privata SSH, password e configurazione reale del router non vengono versionate.

## Comportamento dello script

Quando riceve un'azione `add` valida, lo script estrae `data.src_ip`, verifica sintatticamente l'indirizzo, apre una sessione SSH non interattiva verso RouterOS, aggiunge l'IP alla lista se necessario e rimuove le connessioni corrispondenti dal connection tracking.

La address-list da sola non applica il blocco: il risultato dipende dalle firewall rules effettive.

## Policy osservata durante i test

Lo snapshot della campagna contiene:

- eccezioni per la comunicazione Wazuh;
- drop verso/da host presenti in `Quarantine`;
- regole inter-VLAN;
- regole di accesso VPN;
- FastTrack/established prima dei drop di quarantena nello snapshot storico.

Quest'ultimo punto rende necessario verificare l'ordine delle regole e il connection tracking prima di riusare la policy in un ambiente differente.

## Validazione OFF/ON

La campagna del 1 ottobre 2026 contiene 10 run:

| Modalità | Run | AR osservata | Quarantine | Probe bloccato |
|---|---:|---:|---:|---:|
| OFF | 5 | 0/5 | 0/5 | 0/5 |
| ON | 5 | 5/5 | 5/5 | 5/5 |

Il probe verificava il flusso `10.3.20.2 -> 10.2.0.2:22`. Non è una prova del blocco universale di ogni protocollo.

Dettagli, metriche e limitazioni: [`../../scenarios/active-response/README.md`](../../scenarios/active-response/README.md).

## Cleanup e stato pubblicato

La rimozione dalla quarantena durante la campagna era eseguita dal coordinatore: lo script pubblicato non implementa un rollback automatico equivalente.

Nel `blue-team/wazuh/manager/ossec.conf` incluso nella repository il comando di quarantena è definito, ma il blocco `<active-response>` corrispondente è commentato. Il repository documenta quindi la funzione senza abilitarla implicitamente.

## Sicurezza

Non pubblicare export RouterOS contenenti credenziali, host key private, segreti di management o dati non necessari. Lo snapshot della policy incluso nelle evidenze è ridotto e destinato alla spiegazione del test, non all'importazione diretta.
