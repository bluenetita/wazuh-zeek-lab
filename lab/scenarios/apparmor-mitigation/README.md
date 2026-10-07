# AppArmor Mitigation - servizio inventario

Scenario di hardening del servizio vulnerabile eseguito su ServerDB mediante un profilo AppArmor dedicato e confronto controllato tra modalità complain ed enforce.

## Componenti

- sorgente: [`../../infrastructure/server-db/inventario-service/inventario.c`](../../infrastructure/server-db/inventario-service/inventario.c)
- unit systemd: [`../../infrastructure/server-db/inventario-service/inventario-terminale.service`](../../infrastructure/server-db/inventario-service/inventario-terminale.service)
- profilo: [`../../blue-team/apparmor/profiles/opt.inventario_service.inventario_c`](../../blue-team/apparmor/profiles/opt.inventario_service.inventario_c)

La unit esegue il servizio come `inv-user`, con working directory `/opt/inventario_service` e capability necessaria al bind della porta configurata.

## Metodo

Le prove confrontano la stessa operazione in due stati:

```text
complain -> registra la violazione senza bloccarla
enforce  -> applica la policy e nega ciò che non è autorizzato
```

Per ogni prova vengono osservati stato del profilo, decisione AppArmor, record Audit/SYSCALL, stato del servizio e controllo di disponibilità.

## Serie finale `servicefix`

Evidenze: [`../../evidence/apparmor/2026-10-servicefix/README.md`](../../evidence/apparmor/2026-10-servicefix/README.md).

Risultato su 5 coppie complain/enforce:

| Modalità | `/usr/bin/dash` | SYSCALL | Alert Wazuh |
|---|---|---|---|
| complain | ALLOWED 5/5 | `success=yes`, `exit=0` | non usato come prova di blocco |
| enforce | DENIED 5/5 | `success=no`, `exit=-13` | `130920` nelle 5 prove |

Nella serie finale il servizio risulta `active`, il Main PID rimane invariato e il controllo TCP locale restituisce `rc=0` prima e dopo in tutte le prove.

Il controllo di disponibilità verifica stato systemd e raggiungibilità TCP, non una transazione completa del menu applicativo.

## Serie precedente

[`../../evidence/apparmor/2026-10-01-baseline/README.md`](../../evidence/apparmor/2026-10-01-baseline/README.md) conserva una serie precedente con decisioni complain/enforce coerenti, ma con variazione del PID tra controlli. Per questo non viene usata per affermare continuità del processo.

## Interpretazione

Il risultato dimostra che la policy AppArmor può bloccare l'esecuzione non autorizzata osservata mantenendo disponibile il servizio nel test finale. Non dimostra che il profilo copra ogni possibile vettore né che costituisca una policy completa di produzione.
