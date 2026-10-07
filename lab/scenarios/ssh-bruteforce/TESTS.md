# Test SSH: risultati e procedura di regressione

## Risultati osservati

I risultati dei test reali sono riepilogati in
[observed-test-summaries.jsonl](../../evidence/ssh-bruteforce/observed-test-summaries.jsonl).

| Test | Sequenza osservata (timestamp del Manager, UTC) | Esito osservato |
|---|---|---|
| Coppia positiva | 05/10 16:37:09.654 `120936` A1->V1; 16:37:42.265 login A1->V1 | `120937` |
| Destinazione diversa | 06/10 14:40:12.506 `120936` A1->V1; 14:40:44.742 login A1->V2 | `5715`; nessuna `120937` nell'estratto interrogato |
| Sorgente diversa | 06/10 15:33:10.707 `120936` A1->V1; 15:33:39.357 login A2->V1 | `5715`; nessuna `120937` nell'estratto interrogato |
| Fan-out | 06/10 16:03:46.755 coppia A1->V1; 16:05:58.757 A1->V2 | `120940` |
| Fan-in | 06/10 16:08:44.770 coppia A1->V1; 16:10:44.777 A2->V1 | `120941` |
| Indipendenza | 06/10 16:13:22.790 A1->V1; 16:15:18.797 A2->V2 | Due `120939`; nessuna `120940/120941` nell'estratto |

Non sono disponibili misure di recall/precision, numero sufficiente di repliche
per significativita' statistica o una prova simultanea delle due coppie. La matrice
certifica il risultato dei casi mostrati, non tutti i comportamenti possibili.

## Condizioni della prova

VM: A1 `10.3.20.2`, A2 `10.3.20.4`, V1 `10.3.30.3`, V2 `10.3.30.4`.
I due server avevano agent Wazuh distinti e normalizzazione di `dstip` verificata.
AR di quarantena disattivata durante i test di sola detection. Verificare lo stato
reale prima di ripetere, mantenendo accesso alla console Proxmox.

Per fan-out, fan-in e indipendenza: due sequenze separate da almeno 70 secondi,
completate entro 900 secondi. Il Manager era riavviato tra i test per azzerare lo
stato Wazuh. Un riavvio non e' innocuo in produzione e **non azzera lo stato Zeek**.
Non riavviare il Manager tra le due coppie dello stesso test.

La soglia address scan e' stata portata da 2 a 20. Nel sorgente di questa documentazione
20 e' il valore presente; e' un valore del laboratorio, non una baseline universale.
Il vecchio comando che contatta due IP non riproduce piu' lo scan con soglia 20.
Per ripetere la catena scan->SSH scegliere un test autorizzato coerente con la soglia,
o un profilo di test separato, documentando il cambiamento. Non falsificare un evento
`100918` ne' considerare un mancato prerequisito come un negative test riuscito.

## Un tentativo controllato

Sul client autorizzato, senza privilegi amministrativi:

```bash
ssh -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o NumberOfPasswordPrompts=1 \
    -o ConnectTimeout=5 \
    wazuh_lab_test@10.3.30.3
```

Inserire intenzionalmente una password errata su un account di test non produttivo.
La prima connessione richiede la verifica della chiave host; non disabilitare tale
verifica. L'esito client atteso e' `Permission denied`, non `Connection timed out`.
Ripetere solo quanto necessario per le soglie previste nel laboratorio. Cinque
connessioni non equivalgono per definizione a otto eventi `5710`: vanno verificati i
match reali (una connessione puo' emettere `Invalid user` e `Failed password`).

## Criteri per i negativi

Un negative test e' valido soltanto se prima esiste un antecedente fresco per la
coppia A1->V1 e poi viene osservato il login della coppia differente, con campi
correttamente decodificati. L'assenza dell'alert finale da sola non basta. Per la
prova di indipendenza occorrono entrambe le pair confirmation, non solo l'assenza
di fan-out/fan-in.

I test sintetici si tengono in sessioni `wazuh-logtest` separate dai risultati reali.
Non aggiungere log inventati ad `auth.log` o ai log custom per simulare evidenze.

## Limiti da mantenere nel README

Il controllo `ignore=60`, il gruppo esterno `ssh_pair_confirmed`, l'interazione con
`120936` deve essere interpretata insieme alla detection di scanning e alla coppia SSH confermata.
Attendere 70 s e aumentare una soglia isolano i test, ma non dimostrano che le
correlazioni convivano senza interferenze sotto traffico simultaneo.
