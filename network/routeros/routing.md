# RouterOS Routing

Questo documento descrive il routing configurato su RouterOS.

RouterOS gestisce il routing tra le VLAN interne e inoltra il traffico verso pfSense per raggiungere la rete esterna.

## Reti direttamente connesse

| Rete           | Interfaccia | IP locale RouterOS | Ruolo                |
| -------------- | ----------- | ------------------ | -------------------- |
| `10.3.0.0/16`  | `ether2`    | `10.3.0.1`         | LAN generale / vmbr2 |
| `10.3.10.0/24` | `vlan10`    | `10.3.10.1`        | VLAN Monitoring      |
| `10.3.20.0/24` | `vlan20`    | `10.3.20.1`        | VLAN Client          |
| `10.3.30.0/24` | `vlan30`    | `10.3.30.1`        | VLAN Server          |
| `10.4.0.0/24`  | `ether1`    | `10.4.0.252`       | WAN verso pfSense    |
| `10.5.0.0/24`  | `ether3`    | `10.5.0.1`         | Rete test            |

## Default route

RouterOS usa pfSense come gateway predefinito.

| Destinazione | Gateway      | Interfaccia | Commento              |
| ------------ | ------------ | ----------- | --------------------- |
| `0.0.0.0/0`  | `10.4.0.253` | `ether1`    | Route via WAN pfSense |

Configurazione esportata:

```rsc
/ip route
add comment="Route via WAN pfsense" gateway=10.4.0.253
```

## Rotta VPN

È presente una rotta verso la rete VPN tramite Proxmox.

| Destinazione  | Gateway      | Interfaccia | Commento        |
| ------------- | ------------ | ----------- | --------------- |
| `10.8.0.0/24` | `10.3.0.254` | `ether2`    | VPN via Proxmox |

Configurazione esportata:

```rsc
/ip route
add comment="VPN via Proxmox" dst-address=10.8.0.0/24 gateway=10.3.0.254
```

## Routing inter-VLAN

RouterOS permette il routing tra:

* VLAN 10 - Monitoring;
* VLAN 20 - Client;
* VLAN 30 - Server.

Le regole firewall consentono esplicitamente traffico tra le VLAN principali.

## Flussi principali

| Origine      | Destinazione | Percorso                                     |
| ------------ | ------------ | -------------------------------------------- |
| VLAN 10      | VLAN 20      | `vlan10 -> RouterOS -> vlan20`               |
| VLAN 20      | VLAN 10      | `vlan20 -> RouterOS -> vlan10`               |
| VLAN 10      | VLAN 30      | `vlan10 -> RouterOS -> vlan30`               |
| VLAN 30      | VLAN 10      | `vlan30 -> RouterOS -> vlan10`               |
| VLAN 20      | VLAN 30      | `vlan20 -> RouterOS -> vlan30`               |
| VLAN 30      | VLAN 20      | `vlan30 -> RouterOS -> vlan20`               |
| VLAN interne | Rete esterna | `VLAN -> RouterOS -> ether1 -> pfSense`      |
| VPN          | VLAN interne | `10.8.0.0/24 -> Proxmox -> RouterOS -> VLAN` |

## Note operative

* Il gateway predefinito è pfSense (`10.4.0.253`).
* Il traffico verso la rete esterna passa da `ether1`.
* Le VLAN interne sono direttamente connesse a RouterOS.
* La rete VPN `10.8.0.0/24` è instradata tramite `10.3.0.254`.
* La presenza di NAT su RouterOS può influenzare l'analisi dei log Zeek e pfSense.
