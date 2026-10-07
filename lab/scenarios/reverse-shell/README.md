# Reverse Shell

Scenario di detection e correlazione di connessioni compatibili con reverse shell tramite telemetria Zeek e Wazuh, con integrazione Auditd lato endpoint e test di containment RouterOS.

## Obiettivo

Correlare segnali differenti senza trattare una singola euristica di rete come prova definitiva. La pipeline usa eventi di connessione Zeek, movement, segnali host-based e regole Wazuh.

## Componenti

- Zeek custom logs: `possible_malware.log`, `reverse_shell_live.log`, `reverse_shell_movement.log`, `reverse_shell_final.log`;
- `reverse_shell_movement.zeek` v2;
- decoder Auditd `000_audit_saddr_decoder.xml`;
- correlazioni in `004_zeek_auditd_correlation.xml`;
- correlazioni scanning successive in `005_zeek_scanning_correlation.xml`;
- evidence collector opzionale;
- Active Response RouterOS, validata separatamente OFF/ON.

## Movement detector v2

La condizione principale è:

```text
duration >= 30 s
orig_pkts > 10
resp_pkts > 10
```

Le vecchie soglie sulle dimensioni medie dei pacchetti sono diagnostiche e non bloccano più l'evento. Il detector rivaluta lo stato periodicamente e su nuovi pacchetti e limita a un evento movement per connessione.

File:

```text
blue-team/zeek/site/custom_scripts/reverse_shell/reverse_shell_movement.zeek
```

## Correlazione host/rete

Il Client-Linux raccoglie eventi Auditd relativi alle connessioni e li arricchisce con l'IP locale. Il decoder estrae i campi utili alla correlazione con Zeek. La semantica degli IP nello scenario reverse shell è diversa da quella SSH inbound: l'host compromesso può essere il `src_ip` della connessione outbound.

## Test recuperati

Sono conservati dieci run della campagna utilizzata anche per il confronto Active Response, con record Zeek selezionati, alert Wazuh ed esiti OFF/ON. È presente inoltre un controllo negativo storico separato.

Evidenze:

- [`../../evidence/routeros-ar/2026-10-01/README.md`](../../evidence/routeros-ar/2026-10-01/README.md)
- [`../../evidence/reverse-shell/2026-10-01-negative-control/README.md`](../../evidence/reverse-shell/2026-10-01-negative-control/README.md)

Non viene affermato che ogni run abbia una sequenza completa di tutti i log custom né che l'euristica riconosca tutte le varianti di reverse shell.

## Containment

La quarantena RouterOS è documentata in [`../active-response/README.md`](../active-response/README.md). Nell'export `ossec.conf` pubblicato il blocco che attiverebbe automaticamente la quarantena è commentato.

## Limiti

- le euristiche dipendono dalla visibilità del mirror;
- copie/ritrasmissioni possono influenzare contatori packet-based;
- porte consentite e reti escluse possono creare punti ciechi;
- Zeek non osserva direttamente il processo locale che ha aperto la connessione;
- l'attribuzione finale richiede la combinazione con telemetria host-based.
