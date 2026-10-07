# Reverse shell e RouterOS Active Response: 5 OFF + 5 ON

Campagna del **1 ottobre 2026**.
Le prove `RS-OFF-01` ... `RS-OFF-05` e `RS-ON-01` ... `RS-ON-05` sono mantenute
con i nomi, gli UID e i timestamp originali.

| Condizione | Prove | Live + movement + alert eleggibile | Invocazione AR registrata | Quarantine osservata | Fallimento del probe previsto |
|---|---:|---:|---:|---:|---:|
| OFF | 5 | 5/5 | 0/5 | 0/5 | 0/5 |
| ON | 5 | 5/5 | 5/5 | 5/5 | 5/5 |

Il probe e' eseguito **dal client 10.3.20.2 verso 10.2.0.2 TCP/22**, con timeout
0.5 s e intervallo configurato 0.50 s. Non e' un probe dal Manager alla porta del
client. La baseline richiede 2 conferme e il blocco 2 conferme. `contained_utc`
riporta il primo fallimento della sequenza usata dal riepilogo.

## Tempi descrittivi: conservare il significato delle misure

| Campo della campagna | Definizione | n | Media | Mediana | Min-max |
|---|---|---:|---:|---:|---:|
| T_D | t0 del coordinatore -> alert Wazuh eleggibile | 10 | 33.2141 s | 32.9225 s | 31.938-35.925 s |
| T_AR, ON | alert Wazuh -> riga locale routeros_quarantine | 5 | 0.3578 s | 0.359 s | 0.341-0.372 s |
| T_C, ON | t0 del coordinatore -> primo fallimento probe registrato | 5 | 36.744 s | 36.868 s | 36.269-37.017 s |

I calcoli in [metrics.json](metrics.json) riproducono il [riepilogo originale](metrics_summary.original.txt).
**Non sono tempi universali di contenimento.** T_D include la latenza umana fra GO e
trigger. T_AR usa timestamp dello stesso host Wazuh, ma identifica la riga di
completamento dello script, non il primo pacchetto bloccato. T_C combina clock del
coordinatore e del client, polling e timeout; gli snapshot indicano clock non
sincronizzati. Non sottrarre questi valori per ottenere latenze precise fra host.

Il fallimento del probe, la membership di Quarantine e il messaggio dello script
sono evidenze complementari. Non dimostrano isolamento di **tutti** i protocolli
ne' chiusura indipendentemente verificata della specifica sessione reverse shell
TCP/4444. Il risultato OFF e' assenza di blocco **nell'intervallo osservato**, non
un tempo infinito stimato.

## Evidenze ridotte

- [Matrice originale](routeros_ar_runs.original.tsv) e [verifica per run](verified_runs.jsonl).
- [Alert Wazuh selezionati per UID](selected_wazuh_alerts.jsonl) e [record Zeek](selected_zeek_events.jsonl).
- [Messaggi Active Response](active_response_events.jsonl) e [Quarantine prima/dopo](quarantine.snapshots.txt).
- [Contatori firewall](firewall-counters.snapshots.txt) e [listing della policy](firewall-policy.snapshot.txt).
- Serie complete del probe, con sole righe timestamp/rc valide, in `probes/RS-OFF-01.tsv` ... `probes/RS-ON-05.tsv`.
- [Cleanup del coordinatore](coordinator-cleanup.log): evidenza di rimozione esplicita della quarantena.

Il listing firewall documenta l'ordine osservato, con FastTrack/established prima
dei drop Quarantine. E' uno **snapshot diagnostico**, non un export `.rsc`
importabile e non una policy proposta per produzione. I contatori sono snapshot,
non misure attribuibili univocamente a ciascuna sessione.

Il probe torna raggiungibile nei run ON dopo la fase di cleanup; la campagna invia
esplicitamente la rimozione dalla lista. Questo **non prova un rollback autonomo**
dello script `routeros_quarantine.py`.
La configurazione Manager distribuita rimane con l'azione commentata.

