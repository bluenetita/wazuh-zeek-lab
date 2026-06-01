# RouterOS Firewall Rules

Questo documento descrive le regole firewall configurate su RouterOS.

RouterOS gestisce il routing inter-VLAN e applica regole firewall sulla chain `forward`.

## Obiettivo

Le regole firewall hanno lo scopo di:

* consentire traffico inter-VLAN previsto;
* consentire traffico dalle VLAN verso WAN;
* consentire accessi dalla VPN verso le VLAN;
* bloccare tutto il traffico non esplicitamente consentito.

## Policy generale

La configurazione segue una logica allow-list:

1. accetta traffico established/related;
2. consente traffico tra VLAN autorizzate;
3. consente traffico VLAN verso WAN;
4. consente traffico VPN verso VLAN su porte specifiche;
5. blocca tutto il resto.

## Regole forward

| ID | Chain   | Azione               | Sorgente            | Destinazione        | Protocollo/Porta | Commento                      |
| -: | ------- | -------------------- | ------------------- | ------------------- | ---------------- | ----------------------------- |
|  1 | forward | fasttrack-connection | established/related | established/related | Any              | FastTrack established/related |
|  2 | forward | accept               | established/related | established/related | Any              | Accept established/related    |
|  3 | forward | accept               | `vlan10`            | `vlan20`            | Any              | VLAN10 -> VLAN20              |
|  4 | forward | accept               | `vlan20`            | `vlan10`            | Any              | VLAN20 -> VLAN10              |
|  5 | forward | accept               | `vlan10`            | `vlan30`            | Any              | VLAN10 -> VLAN30              |
|  6 | forward | accept               | `vlan30`            | `vlan10`            | Any              | VLAN30 -> VLAN10              |
|  7 | forward | accept               | `vlan20`            | `vlan30`            | Any              | VLAN20 -> VLAN30              |
|  8 | forward | accept               | `vlan30`            | `vlan20`            | Any              | VLAN30 -> VLAN20              |
|  9 | forward | accept               | `vlan10`            | `ether1`            | Any              | VLAN10 -> WAN                 |
| 10 | forward | accept               | `vlan20`            | `ether1`            | Any              | VLAN20 -> WAN                 |
| 11 | forward | accept               | `vlan30`            | `ether1`            | Any              | VLAN30 -> WAN                 |
| 12 | forward | accept               | `10.8.0.0/24`       | `10.3.0.0/16`       | TCP/22           | VPN SSH to VLANs              |
| 13 | forward | accept               | `10.8.0.0/24`       | `10.3.0.0/16`       | RDP              | VPN RDP to VLANs              |
| 14 | forward | accept               | `10.8.0.0/24`       | `10.3.0.0/16`       | TCP/443          | VPN HTTPS to VLANs            |
| 15 | forward | accept               | `10.8.0.0/24`       | `10.3.0.0/16`       | TCP/80           | VPN HTTP to VLANs             |
| 16 | forward | drop                 | Any                 | Any                 | Any              | Drop everything else          |

## NAT

RouterOS applica masquerade verso `ether1`.

| Chain  | Azione     | Out interface | Commento      |
| ------ | ---------- | ------------- | ------------- |
| srcnat | masquerade | `ether1`      | NAT LAN > WAN |

Configurazione esportata:

```rsc
/ip firewall nat
add action=masquerade chain=srcnat comment="NAT LAN > WAN" out-interface=ether1
```

## Considerazioni

La presenza del masquerade su RouterOS significa che il traffico in uscita verso pfSense può apparire con IP sorgente di RouterOS (`10.4.0.252`) invece dell'IP originale della VM.

Questo è importante per l'analisi di:

* log pfSense;
* log Zeek;
* scenari di data exfiltration;
* reverse shell;
* traffico verso rete esterna.

## Relazione con pfSense

RouterOS filtra e fa NAT prima di inoltrare verso pfSense.

pfSense riceve il traffico da RouterOS sull'interfaccia collegata alla rete `10.4.0.0/24`.

## Note operative

* Il filtraggio principale tra VLAN avviene su RouterOS.
* pfSense controlla il traffico tra RouterOS e rete esterna.
* La regola finale `Drop everything else` rende importante documentare ogni eccezione necessaria agli scenari.
* Se uno scenario non funziona, verificare se il traffico è bloccato da RouterOS prima di arrivare a pfSense.
