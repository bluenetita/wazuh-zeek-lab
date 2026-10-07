# Servizio inventario - sorgente servicefix e unit

Il [sorgente inventario.c](inventario.c) e' una copia byte-per-byte del file
`inventario_service_fixed.c` fornito nella campagna AppArmor servicefix. Lo SHA-256
`30a03bf127db6c7c02fd84c3bbdf4cf1886daff362c8b48e00975656696c4ded`
corrisponde a `service_hashes.txt` della campagna. Il nome pubblicato rispecchia
`/opt/inventario_service/inventario.c` sulla VM; non e' una riscrittura del programma.

La variante gestisce i client in processi figli, usa MSG_NOSIGNAL e gestisce SIGPIPE
per limitare l'impatto delle disconnessioni sul processo principale. **Servicefix
non significa correzione della command injection**: la chiamata `system()` su input
utente resta intenzionalmente vulnerabile. La funzione `verifica_login()` e'
presente ma non chiamata dal percorso `main`/`handle_client` di questa versione.
Non usare il servizio su host di produzione o esposti.

La [unit fornita](inventario-terminale.service) resta invariata: `User=inv-user`,
`WorkingDirectory=/opt/inventario_service`, `Restart=always` e
`AmbientCapabilities=CAP_NET_BIND_SERVICE`. Il commento che menziona `www-data`
non cambia l'utente effettivo. Non e' incluso il binario della VM ne' `utenti.txt`
con credenziali reali.

Per una compilazione locale, nella cartella del sorgente (non avvia il servizio):

```bash
cc -Wall -Wextra -O2 inventario.c -o inventario_c
```

Il comando crea un binario locale e non installa il servizio. L'hash di un nuovo
binario dipende dalla toolchain e non e' garantito identico a quello storico.
Nessuna installazione o esecuzione di rete viene effettuata dall'applicatore della
repository. I dati iniziali `products/` non sono inclusi: la loro ricostruzione
minima va documentata prima di pretendere identica riproducibilita' del servizio.

[Profilo AppArmor](../../../blue-team/apparmor/profiles/opt.inventario_service.inventario_c) -
[Dieci prove finali servicefix](../../../evidence/apparmor/2026-10-servicefix/README.md).
