# Evidenze SSH pubblicabili

Questa cartella distingue deliberatamente **estratti reali**, **riassunti di
terminali** e **campioni storici**. Non contiene risultati sintetici presentati come
misure del laboratorio.

| File | Natura |
|---|---|
| [observed-test-summaries.jsonl](observed-test-summaries.jsonl) | 21 righe trascritte dagli output di test forniti in chat; schema `observed_terminal_projection`, non raw `alerts.json` |
| [zeek-unknown-auth.sample.jsonl](zeek-unknown-auth.sample.jsonl) | Payload reale del caso con 5 sessioni SSH unknown, UID `CREHcO39s2FsWoXzle` |
| [wazuh-pair-unknown-auth.sample.jsonl](wazuh-pair-unknown-auth.sample.jsonl) | Proiezione dell'alert reale `120939` per quello stesso UID |
| [wazuh-scan-pair.sample.jsonl](wazuh-scan-pair.sample.jsonl) | Proiezione dell'alert reale `120936` del 5 ottobre, UID `CXbu2L8xbX57ez1d1` |
| [legacy-known-auth.sample.jsonl](legacy-known-auth.sample.jsonl) | Due eventi storici riportati da `zeekvm/other.txt`; non validano il nuovo fallback |

Il caso reale successivo alle 16:34 del 5 ottobre e' incluso nei riassunti, non
confuso con l'alert `120936` precedente delle 16:27. I timestamp sono conservati;
non vengono "aggiornati" alla data di pubblicazione.

L'assenza di un ID nei risultati di una query e' riferita a quell'intervallo ed
estratto, non prova assenza globale su tutti i log. I negativi riportati hanno un
antecedente osservato e un login osservato; i test multi-coppia restano sequenziali.

I sample non contengono password. Indirizzi e nomi del laboratorio sono mantenuti
per rendere verificabili le coppie; non rappresentano infrastrutture pubbliche.
[Procedura dei test](../../scenarios/ssh-bruteforce/TESTS.md).
