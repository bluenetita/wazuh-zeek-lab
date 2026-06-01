# RouterOS VLANs

Questo documento descrive le VLAN configurate su RouterOS.

## Obiettivo

Le VLAN permettono di separare logicamente i segmenti principali dell'infrastruttura interna.

RouterOS agisce come gateway per ciascuna VLAN e gestisce il routing inter-VLAN.

## VLAN configurate

| VLAN | Nome interfaccia | Parent interface | Subnet         | Gateway RouterOS | Ruolo      |
| ---: | ---------------- | ---------------- | -------------- | ---------------- | ---------- |
|   10 | `vlan10`         | `ether2`         | `10.3.10.0/24` | `10.3.10.1`      | Monitoring |
|   20 | `vlan20`         | `ether2`         | `10.3.20.0/24` | `10.3.20.1`      | Client     |
|   30 | `vlan30`         | `ether2`         | `10.3.30.0/24` | `10.3.30.1`      | Server     |

## VLAN 10 - Monitoring

La VLAN 10 è dedicata ai sistemi di monitoraggio.

Sistemi principali:

* ZeekVM;
* WazuhVM.

Gateway:

```text
10.3.10.1
```

## VLAN 20 - Client

La VLAN 20 è dedicata agli endpoint client.

Sistemi principali:

* ClientVM;
* WindowsVM.

Gateway:

```text
10.3.20.1
```

## VLAN 30 - Server

La VLAN 30 è dedicata ai server interni.

Sistemi principali:

* ServerDB;
* VictimVM.

Gateway:

```text
10.3.30.1
```

## Configurazione RouterOS

Configurazione esportata:

```rsc
/interface vlan
add interface=ether2 name=vlan10 vlan-id=10
add interface=ether2 name=vlan20 vlan-id=20
add interface=ether2 name=vlan30 vlan-id=30
```

Indirizzi IP associati:

```rsc
/ip address
add address=10.3.10.1/24 interface=vlan10 network=10.3.10.0
add address=10.3.20.1/24 interface=vlan20 network=10.3.20.0
add address=10.3.30.1/24 interface=vlan30 network=10.3.30.0
```

## Note operative

* Tutte le VLAN sono configurate sopra `ether2`.
* `ether2` è collegata alla rete interna su `vmbr2`.
* Ogni VM deve usare come gateway l'indirizzo RouterOS della propria VLAN.
* Il traffico tra VLAN viene gestito dalle regole `forward` di RouterOS.
