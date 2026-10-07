# Topologia della validazione SSH

Topologia utilizzata nei test reali del 5-6 ottobre 2026.
Gli ID sono quelli di questa installazione: non devono essere riutilizzati come
credenziali o assegnati manualmente in un altro deployment.

| Sigla | Host / nome agent | IPv4 | Agent Wazuh | Ruolo nella prova |
|---|---|---|---|---|
| A1 | Client-Linux | `10.3.20.2` | `007` | Sorgente SSH 1 |
| A2 | Client-Linux2 | `10.3.20.4` | `013` | Sorgente SSH 2 |
| V1 | ServerDB | `10.3.30.3` | `005` | Server SSH 1 |
| V2 | ServerDB2 | `10.3.30.4` | `012` | Server SSH 2 |
| Sensore | Zeek | `10.3.10.2` | `006` | Osservazione di rete |
| Manager | wazuhvm | `10.3.10.3` | `000` | Correlazione |

Zeek ascolta il mirror su `ens19.999`. I test SSH attraversano le reti client
`10.3.20.0/24` e server `10.3.30.0/24`; questo documento descrive soltanto la topologia necessaria alla validazione SSH e
non sostituisce la documentazione completa di Proxmox/OVS/RouterOS.

```text
A1 10.3.20.2 ----+---- V1 10.3.30.3 --> agent 005 --+
                |                                |
A2 10.3.20.4 ----+---- V2 10.3.30.4 --> agent 012 --+--> Wazuh
                |                                |
                +---- mirror --> Zeek agent 006 --+
```

## Separazione delle identita' dei cloni

ServerDB2 e Client-Linux2 sono stati creati come cloni ma registrati con ID Wazuh
distinti. I cloni riutilizzano le configurazioni base dei rispettivi host, ma hanno
identita Wazuh e indirizzi IP distinti.

Per un nuovo clone: isolare prima la NIC, usare IP/MAC/hostname distinti, non avviare
l'agent con `client.keys` copiato e registrare una nuova identita'. Verificare anche
`machine-id`, chiavi host SSH e identita' dei servizi; la loro rigenerazione non e'
necessaria nel proprio ambiente. Non basta cambiare il nome visualizzato in Proxmox.

Il riuso dello username nei test non confonde la coppia di IP. Il riuso della stessa
password era una scelta del laboratorio, non una raccomandazione per altri ambienti.

In un log V2 era ancora visibile `serverdbvm`: agent `012` e `dstip=10.3.30.4`
erano corretti. L'allineamento del nome emesso dal logging resta da verificare.
