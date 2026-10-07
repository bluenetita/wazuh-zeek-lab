# Controllo negativo di correlazione reverse shell

La [matrice originale](correlation_negative_runs.original.tsv) descrive un solo
controllo `CORR-NEG-01`, `multi_host_same_target`, con precursori presenti su host
diversi, target condiviso `10.2.0.2:22`, finestra 90 s e `forbidden_count=0`.
Il risultato **riportato dalla campagna** e' `VALID_PASS`.

La stessa matrice qualifica il controllo come sintetico/benigno; i dettagli del
trigger non sono inclusi. Non e' una nuova replica di attacco reale, non e' il
test SSH A1->V1 + A2->V2 del 6 ottobre e non dimostra da solo robustezza generale
alla concorrenza. Le dieci prove reali reverse shell OFF/ON sono documentate in
[RouterOS AR](../../routeros-ar/2026-10-01/README.md).
