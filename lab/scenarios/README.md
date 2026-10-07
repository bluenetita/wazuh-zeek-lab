# Scenarios

Questa directory raccoglie gli scenari effettivamente documentati nel cyber range. Ogni scenario collega obiettivo, sistemi coinvolti, detection e risultati osservati; payload, exploit e materiale offensivo riutilizzabile non vengono pubblicati.

## Scenari

| Scenario | Directory | Stato | Componenti principali |
|---|---|---|---|
| Reverse Shell | `reverse-shell/` | Validato | Zeek, Auditd, Wazuh |
| Privilege Escalation | `privilege-escalation/` | Validato | Auditd/Wazuh |
| Network Scanning | `network-scanning/` | Validato | Zeek + Wazuh |
| AppArmor Mitigation | `apparmor-mitigation/` | Validato | ServerDB + AppArmor + Wazuh |
| Active Response | `active-response/` | Validato | Wazuh + RouterOS |
| SSH Brute Force | `ssh-bruteforce/` | Validato | Zeek + sshd + Wazuh |

## Flusso di osservabilità

```text
Traffico di rete  -> Zeek -----------+
                                      |
Eventi host ------> Wazuh Agent ----> Wazuh Manager -> decoder/rules -> alert
                                      |
                                      +-> Active Response (se abilitata)
```

## Principio di validazione

Le prove positive sono accompagnate, quando disponibili, da controlli negativi o confronti OFF/ON. Le evidenze ridotte sono conservate sotto [`../evidence/`](../evidence/README.md).

Nel caso SSH la validazione usa due sorgenti e due vittime per verificare che la correlazione non mescoli sessioni di coppie differenti. Nel caso AppArmor la stessa operazione viene confrontata tra complain ed enforce. Nel caso RouterOS viene confrontato il comportamento con Active Response disabilitata e abilitata.
