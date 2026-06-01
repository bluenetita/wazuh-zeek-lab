# pfSense Interfaces

Questo documento descrive le interfacce pfSense utilizzate nel laboratorio.

## Interfacce

| Nome pfSense | Interfaccia VM | IP / Subnet | Ruolo | Collegamento |
|---|---|---|---|---|
| WAN | vtnet0 | 10.2.0.254/24 | Rete esterna simulata | vmbr1 |
| LAN | vtnet1 | 10.4.0.253/24 | Collegamento interno verso RouterOS | vmbr3 |

## Gateway

| Nome gateway | Interfaccia | Gateway | Ruolo |
|---|---|---|---|
| WANGW_2 | WAN | 10.2.0.1 | Gateway predefinito IPv4 |
| LANGW | LAN | 10.3.0.1 | Gateway lato interno / RouterOS |

## Note

- La WAN è collegata alla rete esterna simulata.
- La LAN è collegata verso RouterOS tramite `vmbr3`.
- Il gateway IPv4 predefinito configurato è `WANGW_2`.