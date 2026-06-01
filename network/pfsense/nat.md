# pfSense NAT

Questo documento descrive la configurazione NAT di pfSense.

## Configurazione attuale

| Tipo | Modalità | Note |
|---|---|---|
| Outbound NAT | Automatic | pfSense gestisce automaticamente le regole NAT in uscita |

## Impatto sul laboratorio

La modalità `automatic outbound NAT` consente a pfSense di creare automaticamente le regole necessarie per permettere alla rete interna di uscire verso la rete esterna.

## Impatto su Zeek

Il NAT può influenzare l'interpretazione dei log di rete.

In particolare, se il traffico viene tradotto da pfSense, alcuni log potrebbero mostrare IP tradotti invece degli IP originali.

Per l'analisi degli scenari è importante annotare:

- se il traffico attraversa pfSense;
- se viene applicato NAT;
- quali IP sono visibili a Zeek;
- quali IP sono visibili nei log pfSense;
- quali IP sono visibili sugli host monitorati da Wazuh.