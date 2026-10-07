# Client Linux

`Client-Linux` è l'endpoint Linux principale della VLAN 20 e partecipa a più scenari del cyber range.

## Rete

| Campo | Valore |
|---|---|
| IP principale | `10.3.20.2/24` |
| VLAN | 20 - Client |
| Gateway | `10.3.20.1` |
| Ruolo SSH | A1 |

Un clone, `Client-Linux2` (`10.3.20.4`), viene usato come A2 nei test SSH con sorgenti indipendenti.

Il traffico verso la VLAN Server passa da RouterOS; il traffico verso la rete esterna simulata prosegue verso pfSense. I file netplan sanificati già presenti nella directory restano validi come riferimento dell'endpoint principale.

## Ruolo negli scenari

Client-Linux viene usato per:

- traffico client legittimo;
- reverse shell controllata e correlazioni Zeek/Wazuh;
- eventi Auditd host-based;
- privilege escalation nel relativo scenario;
- scanning autorizzato;
- sorgente A1 nei test SSH multi-host;
- verifica della quarantena RouterOS nella campagna Active Response.

## Relazione con Zeek

Se il traffico attraversa il punto di mirror, Zeek può osservarne connessioni, DNS, HTTP/TLS e gli eventi generati dagli script custom.

## Wazuh e Auditd

Configurazione aggiornata:

```text
blue-team/wazuh/agent-configs/client-linux-agent-ossec.conf
```

Gli eventi Auditd rilevanti per la correlazione reverse shell vengono arricchiti con l'IP dell'host. Il decoder del Manager usa tali informazioni insieme alla telemetria di rete.

## Active Response

Durante la campagna ON, l'IP `10.3.20.2` è stato osservato nella lista `Quarantine` e il probe TCP previsto verso `10.2.0.2:22` è risultato bloccato. Nelle prove OFF tale comportamento non è stato osservato.

La rimozione della quarantena veniva effettuata dal coordinatore della campagna; non è un rollback automatico dello script.

## Nota

Client-Linux è un endpoint aziendale simulato, non una macchina vulnerabile generica. Le attività offensive documentate sono limitate all'ambiente isolato del cyber range.
