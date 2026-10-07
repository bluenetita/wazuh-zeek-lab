# Evidence

Questa directory contiene evidenze **ridotte e sanificate** dei risultati osservati nel cyber range. La documentazione degli scenari descrive il test; `evidence/` conserva i dati necessari a supportarne l'esito senza pubblicare archivi grezzi completi.

## Evidenze disponibili

| Directory | Contenuto |
|---|---|
| `reverse-shell/` | controllo negativo e collegamenti alla campagna reverse shell |
| `privilege-escalation/` | evidenze host-based già presenti |
| `apparmor/2026-10-01-baseline/` | prima serie complain/enforce |
| `apparmor/2026-10-servicefix/` | serie finale AppArmor 5 complain + 5 enforce |
| `routeros-ar/2026-10-01/` | 5 run OFF + 5 ON, probe, alert selezionati e metriche |
| `ssh-bruteforce/` | campioni Zeek/Wazuh e matrice dei test multi-host |

## Criteri di pubblicazione

Sono ammessi:

- estratti di log strettamente necessari;
- alert Wazuh selezionati;
- JSONL/TSV ridotti;
- snapshot di policy senza segreti;
- metriche aggregate;
- note di validazione.

Non vengono pubblicati:

- log completi del sistema;
- PCAP completi;
- password, token e chiavi;
- dump di processi o journal integrali;
- configurazioni private del router;
- dati personali o file runtime non necessari.

## Relazione con `scenarios/`

```text
scenarios/ -> cosa è stato testato e come interpretarlo
evidence/  -> cosa è stato osservato nelle prove
```

Le assenze di alert vengono descritte solo quando il test ha anche verificato che prerequisiti, coppie IP e altri eventi necessari fossero realmente presenti.
