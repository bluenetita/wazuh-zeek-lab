# pfSense Firewall Rules

Questo documento descrive le regole firewall pfSense utilizzate nel laboratorio.

## Regole attive

| ID | Interfaccia | Azione | Protocollo | Sorgente | Destinazione | Porta | Logging | Motivazione |
|---:|---|---|---|---|---|---|---|---|
| 1 | LAN / Internal | Pass | IPv4 any | LAN net | Any | Any | No | Regola default: consente traffico IPv4 dalla LAN verso qualsiasi destinazione |
| 2 | LAN / Internal | Pass | IPv6 any | LAN net | Any | Any | No | Regola default: consente traffico IPv6 dalla LAN verso qualsiasi destinazione |

## Regole non ancora presenti

Dal file di configurazione attuale non risultano regole custom dedicate agli scenari di attacco.

Regole che potrebbero essere aggiunte o documentate in futuro:

| Scenario | Direzione | Regola prevista |
|---|---|---|
| Reverse Shell | VictimVM → AttackerVM | Consentire traffico TCP verso porta listener controllata |
| SSH Brute Force | AttackerVM → VictimVM | Consentire o bloccare TCP/22 in base al test |
| ICMP Flood | AttackerVM → Target | Consentire o bloccare ICMP in base allo scenario |
| Data Exfiltration | Host interno → External | Consentire traffico HTTP/HTTPS/DNS controllato |
| MITM / Spoofing | Variabile | Dipende dal segmento e dal punto di osservazione |

## Considerazioni

La configurazione attuale è permissiva sul lato LAN, perché permette traffico dalla LAN verso qualsiasi destinazione.

Per scenari più realistici, è consigliabile documentare o configurare regole più specifiche, ad esempio:

- consentire solo traffico necessario;
- abilitare logging sulle regole usate negli scenari;
- distinguere regole permanenti da regole temporanee;
- evitare regole troppo generiche se non motivate.