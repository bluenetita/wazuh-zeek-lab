# AppArmor: serie precedente al servicefix

La [matrice originale](apparmor_runs.original.tsv) contiene 5 coppie complain/enforce.
Gli [eventi selezionati](selected_audit_events.log) confermano ALLOWED in 5/5 prove
complain e DENIED in 5/5 enforce. I [dati runtime verificati](verified_runs.jsonl)
mostrano pero' **Main PID diverso prima/dopo in tutte le 10 prove**.

Il servizio risultava active a entrambi i controlli e il controllo TCP restituiva rc=0,
ma questo non dimostra assenza di riavvii. Non dedurre la causa del cambio di PID
soltanto dai due campioni. La successiva [serie servicefix](../2026-10-servicefix/README.md)
mostra invece PID invariato in 10/10 prove e dispone del sorgente C associato.
Le due serie sono pubblicate separatamente, non aggregate come venti repliche omogenee.

I [cinque alert enforce 130920](selected_wazuh_alerts.jsonl) sono proiezioni selezionate.
La matrice originale conserva le limitazioni `not_independently_measured`;
`verified_runs.jsonl` contiene i valori verificati utilizzati nel riepilogo.
