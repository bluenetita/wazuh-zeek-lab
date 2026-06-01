# pfSense Logging

Questo documento descrive l'utilizzo dei log pfSense nel laboratorio.

pfSense fornisce il punto di vista del firewall: permette di capire se un flusso di traffico tra rete interna ed esterna è stato consentito, bloccato o tradotto tramite NAT.

## Obiettivo

I log pfSense sono utili per:

* verificare se il traffico è stato permesso o bloccato;
* analizzare traffico tra rete interna e rete esterna;
* controllare traffico proveniente da AttackerVM;
* verificare traffico generato dagli scenari di attacco;
* confrontare i log firewall con le evidenze Zeek;
* confrontare i log firewall con gli alert Wazuh;
* supportare il troubleshooting di routing e firewalling.

## Ruolo di pfSense nella visibilità

pfSense non sostituisce Zeek o Wazuh.

Ogni strumento osserva una parte diversa dell'infrastruttura.

| Strumento | Punto di vista                                           |
| --------- | -------------------------------------------------------- |
| pfSense   | Traffico permesso o bloccato dal firewall                |
| Zeek      | Analisi del traffico di rete osservato tramite mirroring |
| Wazuh     | Eventi locali sugli host monitorati                      |

pfSense aiuta a rispondere a domande come:

* il traffico è arrivato al firewall?
* il traffico è stato permesso?
* il traffico è stato bloccato?
* quale interfaccia è stata coinvolta?
* quale regola ha gestito il traffico?
* il traffico visto da Zeek è coerente con le regole firewall?
* l'alert Wazuh corrisponde a un flusso realmente transitato?

## Dove vedere i log

Da interfaccia web pfSense:

```text
Status > System Logs > Firewall
```

Altre sezioni utili:

```text
Diagnostics > States
Diagnostics > Packet Capture
Diagnostics > Routes
Diagnostics > Ping
```

## Log firewall

I log firewall mostrano eventi relativi a pacchetti permessi o bloccati dalle regole.

Campi utili da annotare:

| Campo              | Descrizione                                |
| ------------------ | ------------------------------------------ |
| Timestamp          | Momento in cui il pacchetto è stato visto  |
| Interfaccia        | Interfaccia pfSense coinvolta              |
| Azione             | Pass, Block o Reject                       |
| Protocollo         | TCP, UDP, ICMP                             |
| IP sorgente        | Host che genera il traffico                |
| Porta sorgente     | Porta sorgente del traffico                |
| IP destinazione    | Host destinatario                          |
| Porta destinazione | Porta del servizio contattato              |
| Regola             | Regola firewall che ha gestito il traffico |
| Scenario           | Scenario di test collegato                 |

## Esempio di log sanificato

Esempio puramente documentale:

```text
2026-XX-XX 10:15:20 PASS Internal TCP VICTIM_IP:51514 -> ATTACKER_IP:4444 Scenario reverse shell
```

Altro esempio:

```text
2026-XX-XX 10:22:41 BLOCK External TCP ATTACKER_IP:49212 -> VICTIM_IP:22 Scenario SSH brute force blocked
```

## Sanificazione dei log

Prima di caricare log nella repository, sanificare sempre i dati sensibili.

Sostituire valori reali con placeholder.

| Valore reale     | Placeholder consigliato |
| ---------------- | ----------------------- |
| IP macchina Kali | `ATTACKER_IP`           |
| IP VictimVM      | `VICTIM_IP`             |
| IP ClientVM      | `CLIENT_IP`             |
| IP ServerDB      | `SERVER_DB_IP`          |
| Rete client      | `CLIENT_NET`            |
| Rete server      | `SERVER_NET`            |
| Rete monitoring  | `MONITORING_NET`        |
| Rete interna     | `INTERNAL_NET`          |
| Rete esterna     | `EXTERNAL_NET`          |

Non caricare:

* log completi non filtrati;
* IP pubblici sensibili;
* hostname personali;
* username reali;
* token;
* segreti;
* configurazioni VPN;
* informazioni non necessarie allo scenario.

## Logging sulle regole firewall

Per ottenere log utili, è consigliato abilitare il logging sulle regole più importanti.

Regole su cui può essere utile il logging:

* traffico bloccato dalla rete esterna;
* regole temporanee usate per scenari di attacco;
* traffico verso VictimVM;
* traffico verso ServerDB;
* traffico in uscita da host interni;
* traffico di reverse shell;
* traffico di brute force;
* traffico ICMP flood;
* traffico di data exfiltration.

## Relazione con Zeek

Zeek osserva il traffico duplicato tramite mirroring su Open vSwitch.

I log pfSense aiutano a interpretare i log Zeek.

Esempi:

| Caso                                            | pfSense                     | Zeek                                           |
| ----------------------------------------------- | --------------------------- | ---------------------------------------------- |
| Traffico permesso                               | Log `PASS`                  | Zeek può osservare connessione                 |
| Traffico bloccato prima del segmento monitorato | Log `BLOCK`                 | Zeek potrebbe non vedere il flusso completo    |
| Reverse shell permessa                          | Log `PASS` verso AttackerVM | Zeek può vedere connessione persistente        |
| HTTPS verso esterno                             | Log `PASS`                  | Zeek vede metadati TLS, non contenuto          |
| ICMP bloccato                                   | Log `BLOCK`                 | Zeek potrebbe non vedere traffico verso target |

## Relazione con Wazuh

Wazuh osserva eventi locali sugli host.

I log pfSense possono aiutare a capire se un alert Wazuh è correlato a traffico realmente transitato.

Esempi:

| Caso                     | pfSense                     | Wazuh                                  |
| ------------------------ | --------------------------- | -------------------------------------- |
| SSH brute force permesso | Log `PASS` verso porta 22   | Alert autenticazioni fallite           |
| Reverse shell in uscita  | Log `PASS` verso AttackerVM | Eventuali FIM/eventi host              |
| Data exfiltration        | Log traffico in uscita      | Eventi su file o processi              |
| Traffico bloccato        | Log `BLOCK`                 | Possibile assenza di eventi sul target |

## Uso nei principali scenari

### Reverse Shell

Controllare se pfSense registra traffico dalla macchina vittima verso AttackerVM.

Campi utili:

* IP sorgente: `VICTIM_IP`;
* IP destinazione: `ATTACKER_IP`;
* porta destinazione: porta listener;
* azione: `PASS`;
* protocollo: TCP.

### SSH Brute Force

Controllare traffico da AttackerVM verso il target.

Campi utili:

* IP sorgente: `ATTACKER_IP`;
* IP destinazione: `VICTIM_IP` o `SERVER_IP`;
* porta destinazione: 22;
* azione: `PASS` o `BLOCK`;
* numero di eventi ravvicinati.

### ICMP Flood

Controllare volume e frequenza di eventi ICMP.

Campi utili:

* IP sorgente;
* IP destinazione;
* protocollo ICMP;
* azione;
* frequenza degli eventi.

### Data Exfiltration

Controllare traffico in uscita da host interno verso rete esterna.

Campi utili:

* IP sorgente interno;
* destinazione esterna;
* protocollo;
* porta;
* durata o frequenza del traffico;
* eventuale NAT.

## Packet Capture pfSense

pfSense permette anche di catturare traffico da GUI:

```text
Diagnostics > Packet Capture
```

Questa funzione è utile per verificare rapidamente se un traffico attraversa una certa interfaccia.

Attenzione:

* non caricare PCAP completi nella repository;
* usare solo estratti sanificati;
* preferire descrizioni Markdown e screenshot controllati;
* evitare dati sensibili.

## States

La sezione `Diagnostics > States` è utile per vedere connessioni attive.

Può essere utile durante:

* reverse shell;
* connessioni persistenti;
* test di routing;
* traffico NAT;
* troubleshooting firewall.

## Template per documentare un evento pfSense

Usare questo formato quando si documenta un evento rilevante:

```markdown
## Evento: <nome evento>

| Campo | Valore |
|---|---|
| Scenario | Reverse Shell |
| Timestamp | 2026-XX-XX HH:MM:SS |
| Interfaccia | Internal |
| Azione | PASS |
| Protocollo | TCP |
| Sorgente | VICTIM_IP |
| Destinazione | ATTACKER_IP |
| Porta | 4444 |
| Regola | Allow reverse shell lab test |
| Evidenza Zeek | conn.log / reverse_shell_live.log |
| Evidenza Wazuh | Alert custom / FIM event |
| Note | Connessione coerente con lo scenario |
```

## Best practice

* abilitare logging sulle regole rilevanti;
* usare descrizioni chiare nelle regole firewall;
* evitare log completi non filtrati;
* caricare solo esempi sanificati;
* correlare sempre pfSense, Zeek e Wazuh;
* indicare se il traffico è stato permesso o bloccato;
* annotare se NAT è attivo;
* distinguere test temporanei da regole permanenti.

## Note finali

I log pfSense sono utili soprattutto per verificare il percorso del traffico.

Nel progetto, pfSense fornisce il punto di vista del firewall, Zeek fornisce il punto di vista della rete e Wazuh fornisce il punto di vista degli host.

La combinazione di queste tre fonti migliora la qualità dell'analisi e della correlazione degli scenari.
