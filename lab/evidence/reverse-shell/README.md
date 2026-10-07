# Evidence - Reverse Shell

Questa directory raccoglie evidenze ridotte relative allo scenario reverse shell.

Le prove OFF/ON usate anche per validare il containment RouterOS sono conservate in:

```text
../routeros-ar/2026-10-01/
```

Il controllo negativo storico è in:

```text
2026-10-01-negative-control/
```

La campagna OFF/ON include UID distinti, eventi Zeek selezionati, alert Wazuh e diagnostica movement v2. Non viene presentata come una cattura completa di tutti i log custom per ogni UID.

Per l'interpretazione del detector vedere [`../../scenarios/reverse-shell/README.md`](../../scenarios/reverse-shell/README.md); per il containment vedere [`../../scenarios/active-response/README.md`](../../scenarios/active-response/README.md).
