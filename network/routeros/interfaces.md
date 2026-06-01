# RouterOS Interfaces

Questo documento descrive le interfacce RouterOS utilizzate nel laboratorio.

RouterOS è utilizzato come router inter-VLAN tra i segmenti interni e come nodo di inoltro verso pfSense.

## Interfacce fisiche

| Interfaccia | Tipo     | MAC Address         | Ruolo                      | Collegamento       |
| ----------- | -------- | ------------------- | -------------------------- | ------------------ |
| `ether1`    | Ethernet | `00:60:2F:F1:24:CD` | WAN / uplink verso pfSense | Rete `10.4.0.0/24` |
| `ether2`    | Ethernet | `BC:24:11:54:83:FE` | LAN / trunk VLAN interne   | `vmbr2`            |
| `ether3`    | Ethernet | `BC:24:11:70:7D:13` | TEST                       | `vmbr4-test`       |
| `lo`        | Loopback | `00:00:00:00:00:00` | Loopback                   | Locale             |

## Interfacce VLAN

Le VLAN interne sono configurate su `ether2`.

| Interfaccia VLAN | VLAN ID | Parent interface | Ruolo      |
| ---------------- | ------: | ---------------- | ---------- |
| `vlan10`         |      10 | `ether2`         | Monitoring |
| `vlan20`         |      20 | `ether2`         | Client     |
| `vlan30`         |      30 | `ether2`         | Server     |

## Indirizzi IP

| Interfaccia | IP / Subnet     | Network     | Ruolo                       |
| ----------- | --------------- | ----------- | --------------------------- |
| `ether1`    | `10.4.0.252/24` | `10.4.0.0`  | WAN verso pfSense           |
| `ether2`    | `10.3.0.1/16`   | `10.3.0.0`  | LAN gateway generale per VM |
| `vlan10`    | `10.3.10.1/24`  | `10.3.10.0` | Gateway VLAN 10 Monitoring  |
| `vlan20`    | `10.3.20.1/24`  | `10.3.20.0` | Gateway VLAN 20 Client      |
| `vlan30`    | `10.3.30.1/24`  | `10.3.30.0` | Gateway VLAN 30 Server      |
| `ether3`    | `10.5.0.1/24`   | `10.5.0.0`  | Rete test                   |

## Ruolo delle interfacce

### ether1 - WAN

`ether1` è l'interfaccia di uplink verso pfSense.

È configurata con indirizzo:

```text
10.4.0.252/24
```

La default route di RouterOS punta verso pfSense:

```text
10.4.0.253
```

### ether2 - LAN / trunk VLAN

`ether2` è l'interfaccia collegata alla rete interna su `vmbr2`.

Su questa interfaccia sono configurate le VLAN:

* `vlan10`;
* `vlan20`;
* `vlan30`.

### ether3 - TEST

`ether3` è collegata alla rete di test `vmbr4-test`.

È configurata con indirizzo:

```text
10.5.0.1/24
```

## Note operative

* Le VLAN interne sono configurate come interfacce VLAN sopra `ether2`.
* RouterOS agisce come gateway per VLAN 10, VLAN 20 e VLAN 30.
* Il traffico verso l'esterno viene inoltrato verso pfSense tramite `ether1`.
* Il traffico di test può usare `ether3`, separato dalla rete principale.
