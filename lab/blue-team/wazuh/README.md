# Wazuh

Questa directory contiene la configurazione Wazuh rilevante per il cyber range: agent, decoder, regole custom, correlazioni cross-source e Active Response RouterOS.

## Ruolo

Wazuh riceve sia telemetria host-based sia eventi generati da Zeek. Nel laboratorio viene usato per:

- normalizzare eventi provenienti da sorgenti diverse;
- correlare rete e host;
- distinguere coppie sorgente/destinazione nello scenario SSH;
- correlare reverse shell e telemetria Auditd;
- generare catene di scanning e autenticazione;
- attivare, quando esplicitamente abilitata, la quarantena RouterOS.

## Struttura

| Directory | Contenuto |
|---|---|
| `manager/` | `ossec.conf` del Manager, sanificato |
| `agent-configs/` | configurazioni di ZeekVM, Client-Linux e ServerDB |
| `decoders/` | decoder Auditd/SSH/Zeek SSH |
| `rules/` | regole Zeek, reverse shell, scanning e SSH |
| `active-response/` | script RouterOS ed evidence collector |
| `integrations/`, `log-samples/`, `netplan/` | materiale già presente nella repository |

## Flusso generale

```text
Endpoint / Zeek
      |
  Wazuh Agent
      |
      v
 Wazuh Manager
      |
  Decoder custom
      |
   Ruleset
      |
 Alert / correlazione
      |
 Active Response (solo se abilitata)
```

## Configurazioni agent aggiornate

### ZeekVM

`agent-configs/zeek-agent-ossec.conf` raccoglie i log standard e i log custom. Per `ssh_bruteforce.log` usa un prefisso dedicato:

```text
zeek_ssh_json: <JSON>
```

Questo permette al decoder `010_zeek_ssh_pair_decoder.xml` di distinguere il flusso SSH custom dagli altri JSON Zeek.

### ServerDB

`agent-configs/server-db-agent-ossec.conf` separa `sshd` dal resto dei messaggi journald e raccoglie `/var/log/auth.log` con:

```xml
<out_format>$(log) wazuh_dst_ip=$(host_ip)</out_format>
```

Il suffisso rende disponibile l'endpoint di destinazione al decoder SSH. Nei test V1/V2 i valori osservati erano rispettivamente `10.3.30.3` e `10.3.30.4`.

### Client-Linux

`agent-configs/client-linux-agent-ossec.conf` mantiene la raccolta degli eventi Auditd usati nelle correlazioni reverse shell e arricchisce gli eventi rilevanti con l'IP dell'host.

## Decoder custom

| File | Scopo |
|---|---|
| `000_audit_saddr_decoder.xml` | Estrazione dei campi rilevanti dagli eventi Auditd `rs_connect` |
| `010_zeek_ssh_pair_decoder.xml` | Parsing del JSON SSH Zeek e alias statici `srcip`/`dstip` |
| `0310-ssh_decoders.xml` | Decoder SSH personalizzato con `src_ip`, `dest_ip`, `srcip`, `dstip` |

Il Manager esclude il decoder SSH stock corrispondente per evitare doppie definizioni. Non modificare direttamente il ruleset stock Wazuh.

## Regole e correlazioni

### Zeek e scanning

`rules/002_zeek_rules_custom.xml` contiene le regole custom Zeek, incluse quelle di scanning e SSH. `005_zeek_scanning_correlation.xml` gestisce le correlazioni di scanning nella catena multi-stage.

### Reverse shell + Auditd

`004_zeek_auditd_correlation.xml` collega i segnali di rete con eventi host-based. La semantica degli IP dipende dallo scenario: in una reverse shell outbound l'host compromesso può essere la sorgente della connessione.

### SSH brute force

`9999_ssh_bruteforce_correlation.xml` usa la coppia ordinata sorgente/destinazione. Le regole principali sono:

| ID | Funzione |
|---|---|
| `100920` | candidato SSH dal sensore Zeek |
| `100921` | successo SSH inferito dal percorso Zeek quando disponibile |
| `120935` | Zeek prima, fallimenti endpoint dopo |
| `120938` | fallimenti endpoint valid-user prima, Zeek dopo |
| `120939` | fallimenti endpoint invalid-user prima, Zeek dopo |
| `120936` | scanning precedente + brute force SSH confermato |
| `120937` | autenticazione SSH riuscita dopo la catena, stessa coppia IP |
| `120940` | fan-out: stessa sorgente, vittime differenti |
| `120941` | fan-in: sorgenti differenti, stessa vittima |

Le correlazioni cross-agent usano `global_frequency` dove necessario. I campi statici `srcip`/`dstip` vengono usati per i confronti di coppia.

## Validazione SSH

La matrice reale include:

| Caso | Esito |
|---|---|
| A1->V1 confermata | positivo |
| antecedente A1->V1 + login A1->V2 | nessuna `120937` |
| antecedente A1->V1 + login A2->V1 | nessuna `120937` |
| A1->V1 + A1->V2 | `120940` |
| A1->V1 + A2->V1 | `120941` |
| A1->V1 + A2->V2 | due `120939`, nessun falso meta-alert |

Dettagli: [`../../scenarios/ssh-bruteforce/TESTS.md`](../../scenarios/ssh-bruteforce/TESTS.md).

## Active Response RouterOS

`active-response/routeros_quarantine.py` riceve un alert Wazuh, legge `data.src_ip` e usa SSH con chiave dedicata per aggiungere l'IP alla address-list `Quarantine` e rimuovere le connessioni attive dal connection tracking.

La configurazione privata è esterna alla repository. `routeros.conf.example` contiene esclusivamente placeholder.

**Stato dell'export Manager incluso:** il comando è definito, ma il blocco `<active-response>` della quarantena è commentato. Copiare la configurazione non abilita automaticamente il contenimento.

Le prove OFF/ON sono documentate in [`../../scenarios/active-response/README.md`](../../scenarios/active-response/README.md).

## Verifiche

Prima di applicare modifiche sul Manager:

```bash
sudo /var/ossec/bin/wazuh-analysisd -t
```

Per analizzare un evento in sessione di test:

```bash
sudo /var/ossec/bin/wazuh-logtest
```

Un test `wazuh-logtest` non sostituisce la verifica end-to-end sul Manager live e non simula automaticamente agent distinti.

## Sicurezza

Non versionare `client.keys`, `authd.pass`, chiavi private, webhook reali, credenziali RouterOS, archivi completi degli alert o output dell'evidence collector contenenti dati sensibili.
