# Active Response RouterOS

Scenario di containment automatico in cui Wazuh può inserire l'IP sorgente di un alert nella address-list RouterOS `Quarantine` tramite SSH con chiave dedicata.

## Implementazione

Script:

```text
blue-team/wazuh/active-response/routeros_quarantine.py
```

Configurazione pubblicabile:

```text
blue-team/wazuh/active-response/routeros.conf.example
```

Lo script:

1. legge il messaggio Active Response da `stdin`;
2. accetta `command=add`;
3. estrae `parameters.alert.data.src_ip`;
4. valida l'indirizzo;
5. usa SSH non interattivo verso RouterOS;
6. aggiunge l'IP alla lista `Quarantine` se assente;
7. rimuove le connessioni corrispondenti dal connection tracking;
8. registra l'esito in `active-responses.log`.

La chiave privata e la configurazione reale del router non sono versionate.

## Stato della configurazione pubblicata

Nel `manager/ossec.conf` incluso il comando `quarantine-routeros` è definito, ma il relativo blocco `<active-response>` è commentato. La copia dei file nella repository **non abilita** la quarantena nel laboratorio.

## Policy RouterOS osservata

Lo snapshot della campagna contiene regole dedicate alla lista `Quarantine`, insieme a eccezioni per il traffico Wazuh. È presente FastTrack prima dei drop di quarantena nello snapshot storico: l'ordine delle regole va quindi rivalutato prima di usare questa configurazione come policy di produzione.

La address-list, da sola, non blocca traffico: il containment dipende dalle firewall rules effettive.

## Validazione OFF/ON

Campagna: [`../../evidence/routeros-ar/2026-10-01/README.md`](../../evidence/routeros-ar/2026-10-01/README.md).

| Modalità | Run | Invocazione AR | Quarantine | Probe bloccato |
|---|---:|---:|---:|---:|
| OFF | 5 | 0/5 | 0/5 | 0/5 |
| ON | 5 | 5/5 | 5/5 | 5/5 |

Dalle timestamp della campagna:

- media `T_AR`: circa **0,358 s** dall'alert Wazuh al completamento loggato della risposta;
- media `T_C`: circa **36,744 s** dal GO del coordinatore al contenimento osservato dal probe.

Le due metriche hanno origine temporale differente e non devono essere confrontate come se misurassero lo stesso tratto della pipeline. `T_C` include trigger umano, polling e timeout del probe.

Il probe verificava il flusso `10.3.20.2 -> 10.2.0.2:22`; non dimostra il blocco di qualunque protocollo o di ogni connessione preesistente.

## Cleanup

La rimozione dalla quarantena nella campagna era eseguita esplicitamente dal coordinatore. Lo script pubblicato non implementa un rollback automatico equivalente su `command=delete`.

## Sicurezza

La versione pubblicata è una baseline di laboratorio. Prima di un uso operativo vanno rivisti almeno: allowlist di management, durata della quarantena, comportamento IPv6, ordine FastTrack/firewall, selezione esatta delle connessioni da rimuovere e strategia di rollback.
