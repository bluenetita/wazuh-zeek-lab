# Full Multi-Stage Attack Chain

This document connects the laboratory exercises into an end-to-end defensive validation path without publishing reusable attack commands.

```text
Suspicious file delivery / reverse-shell behavior
    -> Endpoint/network correlation
    -> Privilege-related activity
    -> Post-compromise network reconnaissance
    -> ServerDB service discovery
    -> Unsafe application-input execution attempt
    -> AppArmor observation or prevention
    -> Later access/pivot and SSH authentication stage
```

## Defensive coverage matrix

| Stage | Main defensive source | Status |
|---|---|---|
| Reverse-shell behavior | Zeek + Auditd + Wazuh correlation | Implemented |
| Privilege activity | Auditd + Wazuh | Implemented |
| Network scanning | Zeek custom scanning + Wazuh | Implemented |
| Reverse shell -> scanning | Wazuh `120927-120934` | Implemented |
| ServerDB AppArmor event collection | Audit/AppArmor + Wazuh Agent | Implemented |
| AppArmor denial classification | Decoder + `006_app_armor.xml` | Implemented |
| AppArmor enforce-mode prevention | AppArmor profile | Implemented/tested in lab |
| Pivot/port-forward custom detection | No dedicated custom rule in this update | Gap |
| SSH brute-force custom correlation | No dedicated custom rule in this update | Gap/future work |

## Interpretation

The scenario is valuable because not every stage has the same visibility. The repository should distinguish implemented detections from steps that are only simulated or observed manually.
