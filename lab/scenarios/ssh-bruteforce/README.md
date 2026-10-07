# SSH brute force: normalizzazione endpoint e correlazione multi-host

## Obiettivo

Distinguere `A1 -> V1`, `A1 -> V2`, `A2 -> V1` e `A2 -> V2`, evitando che un login
su un endpoint differente chiuda la catena di un altro endpoint. Il normalizer non
e' un programma esterno: usa `out_format` nativo dell'agent e decoder XML sul Manager.

[Topologia](../../docs/topology-ssh-validation-2026-10.md) -
[Test](TESTS.md) - [Evidenze](../../evidence/ssh-bruteforce/README.md).

## Percorso endpoint

Sul server SSH, il collector di `/var/log/auth.log` seleziona `sshd` e aggiunge:

```xml
<out_format>$(log) wazuh_dst_ip=$(host_ip)</out_format>
```

Il decoder conserva `srcip` ed estrae `dstip`; aggiunge gli alias dinamici `src_ip`
e `dest_ip`. L'agent ServerDB raccoglie inoltre gli eventi non-SSH da journald per
non duplicare volontariamente la stessa sorgente SSH. La configurazione effettiva
va verificata anche in presenza di `agent.conf` centralizzati.

`$(host_ip)` e' un indirizzo selezionato dall'agent: non e' la prova dell'indirizzo
locale effettivo di ogni socket SSH, ne' coincide per definizione con l'IP di
enrollment. Nei test i valori erano V1 `10.3.30.3` e V2 `10.3.30.4`. Su host
multi-homed, NAT, alias IP o porte multiple, la semantica va riesaminata.

## Percorso rete e risultato unknown

Lo script mantiene uno stato distinto per `[src, dst, dport]`. `ssh_auth_result`
tratta gli esiti inferiti dall'analizzatore SSH; `SSH::log_ssh` considera invece le
sessioni per cui `auth_success` non e' valorizzato. I due percorsi non incrementano
volontariamente la stessa sessione quando il risultato e' presente.

Nel fallback: `failed_connections=0`, `unknown_connections=5`, `auth_attempts=0`,
`auth_success` assente. Questa e' **attivita' SSH ripetuta candidata**, non la prova
di cinque password sbagliate. La verifica dei fallimenti proviene da `sshd` via Wazuh.
Anche l'esito auth noto a Zeek resta un'inferenza di rete, non un audit del server.

Il collector Zeek invia il solo log custom con `zeek_ssh_json: `; il decoder dedicato
usa `JSON_Decoder` e aggiunge gli alias statici IPv4 per la correlazione.

## Regole di correlazione

| ID | Funzione | Finestra | Chiave |
|---|---|---|---|
| 100922 | Base del decoder JSON SSH dedicato | Evento singolo | Location + origine Zeek |
| 100920 | Candidato SSH dal sensore | Soglie nello script Zeek | Campi rete |
| 100921 | Successo inferito dopo pattern SSH | Follow-up dello script | `[src,dst,dport]` |
| 5712 / 5763 | Aggregazione endpoint stock | 8 eventi / 120 s; `ignore=60` osservato | Sorgente nel contesto agent |
| 120935 | Zeek precedente + fallimenti endpoint | 300 s | `srcip`, `dstip`, cross-agent |
| 120938 / 120939 | Fallimenti endpoint precedenti + Zeek | 300 s | `srcip`, `dstip`, cross-agent |
| 120936 | Scan precedente + coppia SSH confermata | 900 s | `src_ip` dello scanner |
| 120937 | Login riuscito dopo 120936 | 900 s | Stessa coppia di IP |
| 120940 | Fan-out | 900 s, frequency 2 | Stessa sorgente, destinazione diversa |
| 120941 | Fan-in | 900 s, frequency 2 | Sorgente diversa, stessa destinazione |

La `120936` e' intenzionalmente source-oriented: lo scan multi-target non offre
necessariamente una singola vittima da confrontare. La `120937` richiede entrambi
gli IP, ma **non richiede lo stesso username** del brute force. Il test positivo ha
usato tentativi su utente inesistente e successivamente login dell'utente reale
`serverdb`; dimostra la catena per host, non il recupero della password di quell'utente.

`global_frequency` permette la correlazione tra agent sul medesimo Manager. Non e'
una correlazione distribuita tra nodi di cluster.

## Soglie e stato

Zeek: 5 connessioni rilevanti oppure 5 tentativi inferiti, finestra di 60 s ancorata
al primo evento della sequenza, scadenza dello stato dopo 10 min senza scritture.
Follow-up successo: 5 min dall'ultimo evento della sequenza. Questi valori descrivono
la configurazione del laboratorio, non una finestra mobile esatta certificata in ogni carico.

Gli esperimenti fan-out/fan-in hanno usato una pausa di 70 s fra le coppie per non
interferire con `ignore=60` della regola stock. Questo e' un **limite della prova**:
la pausa rende il test sequenziale e non corregge i possibili mancati alert di attacchi
contemporanei. Non dichiarare supporto alla concorrenza sulla sola base di tali prove.

Nel ruleset `ssh_pair_confirmed` e' anche nel gruppo esterno: viene assegnato
alle altre regole contenute, non esclusivamente alle prime tre pair confirmation.
Questa semantica e' conservata, ma e' un punto di regressione da verificare prima di
estendere il ruleset. Non viene modificata nascostamente durante la pubblicazione.

## Sicurezza e pubblicazione

La configurazione pubblicata non abilita nuove quarantene per gli alert SSH. Il Python RouterOS
fornito seleziona `data.src_ip`: nella reverse shell rappresenta il client sospetto,
nello scenario SSH rappresenta la sorgente dei tentativi. Non collegare automaticamente
le nuove regole alla stessa Active Response senza definire la policy.

Le descrizioni originali di `100920`/`100921` sono conservate. Con esito unknown,
leggere anche `detection_reason` e i contatori: la descrizione legacy "brute force
detected" non trasforma un candidato di rete in un fallimento certo.

