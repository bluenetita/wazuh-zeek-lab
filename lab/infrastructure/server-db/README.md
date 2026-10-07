# ServerDB

`ServerDB` è un server interno della VLAN 30. In origine documentato principalmente come database PostgreSQL, nello stato finale del laboratorio ospita anche il servizio inventario usato per lo scenario AppArmor ed è la vittima V1 della validazione SSH Endpoint Normalizer.

## Rete

| Campo | Valore |
|---|---|
| Nome | `ServerDB` |
| IP | `10.3.30.3/24` |
| VLAN | 30 - Server |
| Gateway | `10.3.30.1` |
| Ruolo SSH | V1 |

`ServerDB2` (`10.3.30.4`) è un clone usato come V2 nei test multi-victim SSH. Non è necessario duplicarne l'intera configurazione nella repository.

## Servizi

### PostgreSQL

Il server mantiene il ruolo di database interno. I file di configurazione e i log PostgreSQL vanno pubblicati solo se sanificati.

### Servizio inventario

La directory [`inventario-service/`](inventario-service/README.md) contiene:

```text
inventario.c
inventario-terminale.service
README.md
```

La unit esegue il servizio come `inv-user` e costituisce il target dello scenario AppArmor.

## AppArmor

Profilo:

```text
blue-team/apparmor/profiles/opt.inventario_service.inventario_c
```

La serie finale `servicefix` confronta 5 prove complain e 5 enforce. L'esecuzione osservata di `/usr/bin/dash` è consentita in complain e negata in enforce; nelle prove enforce sono presenti gli alert Wazuh previsti. Il servizio rimane `active` e il Main PID resta invariato nella serie finale.

Vedere [`../../scenarios/apparmor-mitigation/README.md`](../../scenarios/apparmor-mitigation/README.md).

## SSH Endpoint Normalizer

La configurazione Wazuh dell'host raccoglie `sshd` da `/var/log/auth.log` e aggiunge:

```text
wazuh_dst_ip=$(host_ip)
```

Il decoder del Manager produce sia `dstip` sia `dest_ip`, permettendo di distinguere gli eventi diretti a V1 da quelli diretti a V2. Questo evita correlazioni basate soltanto sull'attacker quando lo stesso source host contatta più server.

Vedere [`../../scenarios/ssh-bruteforce/README.md`](../../scenarios/ssh-bruteforce/README.md).

## Relazione con Zeek

Il traffico da/verso ServerDB può essere osservato dal sensore quando attraversa il punto di mirror. Zeek fornisce i metadati di rete, mentre Wazuh fornisce autenticazioni, log di sistema, eventi del servizio e telemetria host-based.

## File da non pubblicare

Non versionare credenziali del database, file utenti reali del servizio, chiavi private, log completi o dati runtime non necessari.
