# AppArmor: serie servicefix, 5 coppie complain/enforce

I timestamp `t0_utc` vanno dal **1 ottobre 2026, 23:08:58.900Z** al
**1 ottobre 2026, 23:15:12.127Z**: il nome della campagna riporta 20261002,
ma non sono stati riscritti i timestamp UTC.

## Risultati verificati sui file di ciascuna prova

| Condizione | Prove | Decisione per exec di /usr/bin/dash | SYSCALL con stesso audit ID | Servizio active prima/dopo | Main PID invariato | Health-check rc=0 prima/dopo |
|---|---:|---|---|---:|---:|---:|
| complain | 5 | ALLOWED, 5/5 | success=yes, exit=0, 5/5 | 5/5 | 5/5 | 5/5 |
| enforce | 5 | DENIED, 5/5 | success=no, exit=-13, 5/5 | 5/5 | 5/5 | 5/5 |

Le 5 prove enforce hanno anche un alert Wazuh `130920` corrispondente all'audit ID
selezionato. Le due condizioni sono mantenute separate e accoppiate tramite
`AA-SVCFIX-P01` ... `AA-SVCFIX-P05`. Il confronto riguarda l'operazione osservata,
non una percentuale generale di efficacia contro qualsiasi attacco.

## Dati inclusi

- [Tabella originale](apparmor_runs.original.tsv): copia della matrice della campagna.
- [Righe verificate](verified_runs.jsonl): valori estratti dai file runtime per ciascuna prova.
- [AVC e SYSCALL selezionate](selected_audit_events.log): solo l'evento AppArmor rilevante e la syscall con stesso identificatore audit.
- [Alert Wazuh ridotti](selected_wazuh_alerts.jsonl): proiezioni degli alert 130920, non un export integrale.
- [Snapshot della unit](inventario-terminale.service.snapshot.txt).

La matrice originale ha `service_active_before/after=[SSH password prompt]`:
si tratta di contaminazione del campo durante la raccolta, **non** dello stato
systemd. I rispettivi `service_active_*.txt` contengono `active` e i file
`main_pid_*.txt` permettono il confronto dei PID. I valori corretti sono pubblicati
nel file derivato, senza alterare silenziosamente la matrice originale.

La colonna originale `syscall_result=not_independently_measured` e la nota
`independent_outcome_check=not_configured` sono conservate. Le SYSCALL audit gia presenti nelle evidenze permettono di verificare il risultato
della chiamata di sistema; non sostituiscono un ulteriore test applicativo indipendente.
Per `AA-C-SVCFIX-03` AVC e SYSCALL sono presenti in `audit_after_marker_poll.txt`,
non nel file `audit_after_marker_full.log`; il file derivato registra questa differenza.

## Cosa misura il controllo di disponibilita'

Il comando configurato era `systemctl is-active --quiet inventario-terminale.service`
seguito da una connessione TCP a `127.0.0.1:80` con timeout 2 s. Quindi il risultato
conferma **servizio attivo e porta locale raggiungibile**; non certifica la corretta
esecuzione di una transazione del menu inventario. La continuita' del Main PID e'
verificata ai due istanti raccolti, non e' un monitoraggio continuo.

## Relazione con sorgente e profilo

Il [sorgente inventario.c](../../../infrastructure/server-db/inventario-service/inventario.c)
e il profilo AppArmor incluso rappresentano i componenti dello scenario documentato.
Le prove finali mostrano il comportamento complain/enforce descritto sopra.

La [serie precedente](../2026-10-01-baseline/README.md) non viene sommata a questa:
mostra PID differenti fra prima e dopo. Usare servicefix per descrivere la continuita'
del processo osservata nelle prove finali.

