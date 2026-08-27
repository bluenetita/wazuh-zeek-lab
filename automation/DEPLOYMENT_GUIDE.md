# Guida al deployment del laboratorio Zeek con Terraform e Ansible

Questa guida descrive come utilizzare il progetto per creare una VM Zeek su Proxmox con **Terraform** e configurarla automaticamente con **Ansible**.

Il flusso previsto è:

```text
Terraform
  |
  +-- clona il template Ubuntu Cloud-Init
  +-- crea CPU, RAM, disco e NIC
  +-- configura IP e gateway management
  +-- crea l'utente Cloud-Init
  +-- installa la chiave SSH pubblica
  |
  v
VM Ubuntu pronta e raggiungibile via SSH
  |
  v
Ansible
  |
  +-- configura ens19 e ens19.999
  +-- installa Zeek 8.0.6 dall'artifact precompilato
  +-- distribuisce configurazioni e custom script Zeek
  +-- abilita il promiscuous mode
  +-- installa e configura Wazuh Agent
  +-- avvia e verifica Zeek
  +-- applica l'hardening finale dell'utente
  |
  v
VM Zeek pronta
```

> **Importante:** Terraform gestisce l'infrastruttura Proxmox e il bootstrap della VM. Ansible gestisce la configurazione interna del sistema operativo.

---

## 1. Struttura del progetto

La struttura principale è simile alla seguente:

```text
wazuh-zeek-terraform-lab/
|
+-- ansible.cfg
+-- main.tf
+-- provider.tf
+-- variables.tf
+-- outputs.tf
+-- versions.tf
+-- terraform.tfvars
+-- terraform.tfvars.example
+-- .gitignore
|
+-- modules/
|   +-- proxmox-vm/
|       +-- main.tf
|       +-- variables.tf
|       +-- outputs.tf
|       +-- versions.tf
|
+-- ansible/
    +-- artifacts/
    |   +-- zeek-8.0.6/
    |       +-- zeek-8.0.6-ubuntu24.04-amd64.tar.gz
    |       +-- zeek-8.0.6-ubuntu24.04-amd64.sha256
    |
    +-- inventory/
    |   +-- lab.yml
    |   +-- group_vars/
    |       +-- wazuh_agents.yml
    |       +-- zeek_sensors/
    |           +-- main.yml
    |           +-- vault.yml
    |
    +-- playbooks/
    |   +-- site.yml
    |   +-- zeek.yml
    |
    +-- roles/
        +-- zeek/
        +-- wazuh_agent/
        +-- hardening/
```

Il progetto è pensato per essere esteso in futuro con altre VM e altri ruoli Ansible.

---

# PARTE I - TERRAFORM

## 2. Prerequisiti Terraform

Prima di utilizzare Terraform servono:

- un server Proxmox raggiungibile dalla macchina di amministrazione;
- un API token Proxmox con i permessi necessari;
- un template Ubuntu 24.04 Cloud-Init già presente su Proxmox;
- `qemu-guest-agent` installato e attivo nel template;
- una chiave SSH pubblica da installare nella VM;
- Terraform installato sulla macchina da cui viene eseguito il progetto.

Il provider utilizzato dal progetto è `bpg/proxmox`.

---

## 3. Preparare `terraform.tfvars`

Il repository deve contenere un file di esempio:

```text
terraform.tfvars.example
```

Creare il file reale:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Su Windows PowerShell si può semplicemente copiare il file dall'Explorer oppure usare:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` contiene valori specifici dell'ambiente e **non deve essere pubblicato su Git**.

---

## 4. Parametri globali Terraform

All'inizio di `terraform.tfvars` sono presenti i parametri relativi a Proxmox e al template.

Esempio:

```hcl
proxmox_endpoint  = "https://PROXMOX_IP:8006/"
proxmox_insecure  = true
proxmox_api_token = "terraform@pve!provider=TOKEN_SECRET"

template_vm_id     = 9000
template_node_name = "NOME_NODO_PROXMOX"
datastore_id       = "local"

cloud_init_username = "prova"
ssh_public_key      = "ssh-ed25519 CHIAVE_PUBBLICA"
```

### `proxmox_endpoint`

Indirizzo delle API Proxmox.

```hcl
proxmox_endpoint = "https://10.0.0.10:8006/"
```

### `proxmox_insecure`

Nel laboratorio può essere impostato a `true` se Proxmox utilizza un certificato TLS self-signed.

```hcl
proxmox_insecure = true
```

### `proxmox_api_token`

Token utilizzato da Terraform per autenticarsi su Proxmox.

```hcl
proxmox_api_token = "utente@pve!token=SECRET"
```

Non pubblicare mai il valore reale.

### `template_vm_id`

VMID del template Ubuntu Cloud-Init da clonare.

```hcl
template_vm_id = 9000
```

Se il template ha un altro ID, modificare questo parametro.

### `template_node_name`

Nodo Proxmox sul quale risiede il template.

```hcl
template_node_name = "bn-pvelab02"
```

### `datastore_id`

Storage Proxmox utilizzato per il disco della VM.

```hcl
datastore_id = "local"
```

### `cloud_init_username`

Utente Linux creato tramite Cloud-Init.

```hcl
cloud_init_username = "prova"
```

Lo stesso username dovrà essere usato successivamente in Ansible come `ansible_user`.

### `ssh_public_key`

Chiave pubblica SSH autorizzata nella VM.

Esempio:

```hcl
ssh_public_key = "ssh-ed25519 AAAA..."
```

La corrispondente **chiave privata** verrà utilizzata da Ansible.

---

## 5. Configurare la VM Zeek

Le VM vengono definite nella mappa:

```hcl
vms = {
  ...
}
```

Esempio:

```hcl
vms = {
  zeek-tf = {
    vmid      = 110
    node_name = "bn-pvelab02"

    cores     = 2
    memory    = 8192
    disk_size = 50

    cpu_type   = "x86-64-v2-AES"
    full_clone = false
    started    = true
    on_boot    = true

    description = "Passive Zeek sensor - managed by Terraform"

    tags = [
      "monitoring",
      "zeek"
    ]

    networks = [
      {
        bridge   = "vmbr2"
        vlan_id  = 10
        firewall = false
      },
      {
        bridge   = "vmbr2"
        firewall = false
      }
    ]

    management = {
      ipv4    = "10.3.10.2/24"
      gateway = "10.3.10.1"
    }
  }
}
```

---

## 6. Come cambiare il nome della VM

Il nome è la chiave della mappa `vms`.

Da:

```hcl
vms = {
  zeek-tf = {
```

A, per esempio:

```hcl
vms = {
  zeek-production = {
```

Questo nome viene passato al modulo come nome della VM Proxmox.

> Cambiare la chiave di una risorsa gestita con `for_each` può essere interpretato da Terraform come rimozione della vecchia istanza e creazione di una nuova. Controllare sempre `terraform plan` prima di applicare la modifica.

---

## 7. Come cambiare il VMID

Modificare:

```hcl
vmid = 110
```

Esempio:

```hcl
vmid = 250
```

Il VMID deve essere libero sul cluster/nodo Proxmox.

---

## 8. Come cambiare il nodo Proxmox

Modificare:

```hcl
node_name = "bn-pvelab02"
```

con il nodo sul quale si vuole creare la VM.

Il parametro `template_node_name` resta invece il nodo sul quale si trova il template da clonare.

---

## 9. Come cambiare CPU, RAM e disco

CPU:

```hcl
cores = 2
```

RAM, espressa in MiB:

```hcl
memory = 8192
```

Disco, espresso in GiB:

```hcl
disk_size = 50
```

Esempio:

```hcl
cores     = 4
memory    = 16384
disk_size = 100
```

---

## 10. Come cambiare l'indirizzo IP della Zeek VM

Modificare la sezione:

```hcl
management = {
  ipv4    = "10.3.10.2/24"
  gateway = "10.3.10.1"
}
```

Per esempio:

```hcl
management = {
  ipv4    = "10.3.10.4/24"
  gateway = "10.3.10.1"
}
```

Dopo aver cambiato l'IP in Terraform, bisogna cambiare **lo stesso indirizzo anche nell'inventory Ansible**. La procedura è descritta nella sezione Ansible.

---

## 11. Configurazione delle NIC della Zeek VM

La Zeek VM utilizza due NIC:

```text
net0 -> management
net1 -> cattura traffico mirrored
```

La configurazione Terraform è:

```hcl
networks = [
  {
    bridge   = "vmbr2"
    vlan_id  = 10
    firewall = false
  },
  {
    bridge   = "vmbr2"
    firewall = false
  }
]
```

### Prima NIC - Management

```hcl
{
  bridge   = "vmbr2"
  vlan_id  = 10
  firewall = false
}
```

È collegata alla VLAN di management.

Cloud-Init configura IP e gateway su questa NIC.

### Seconda NIC - Capture

```hcl
{
  bridge   = "vmbr2"
  firewall = false
}
```

Non deve avere il tag VLAN 999 configurato direttamente da Proxmox nel setup attuale.

Ansible crea dentro Ubuntu:

```text
ens19.999
```

sopra:

```text
ens19
```

per ricevere il traffico mirrored con VLAN 999.

> L'ordine degli elementi in `networks` è importante: la prima NIC è la management, la seconda è la capture.

---

## 12. Linked clone e full clone

Il parametro:

```hcl
full_clone = false
```

usa un clone non-full quando supportato dalla configurazione Proxmox/template.

Per richiedere un full clone:

```hcl
full_clone = true
```

---

## 13. Avvio automatico della VM

```hcl
started = true
on_boot = true
```

- `started = true`: la VM viene avviata dopo la creazione.
- `on_boot = true`: Proxmox avvia la VM automaticamente all'avvio del nodo.

---

## 14. Comandi Terraform

Posizionarsi nella root del progetto:

```bash
cd wazuh-zeek-terraform-lab
```

### Inizializzazione

La prima volta:

```bash
terraform init
```

### Formattazione

```bash
terraform fmt -recursive
```

### Validazione

```bash
terraform validate
```

### Visualizzare le modifiche previste

```bash
terraform plan
```

Leggere attentamente il piano prima di procedere.

### Creare o modificare le VM

```bash
terraform apply
```

Confermare digitando:

```text
yes
```

### Visualizzare gli output

```bash
terraform output
```

L'output `virtual_machines` mostra VMID, nodo e IP management delle VM gestite.

### Distruggere le risorse Terraform

```bash
terraform destroy
```

Usare questo comando con attenzione: elimina le VM gestite dallo state Terraform.

---

## 15. File Terraform da non pubblicare

Non devono essere versionati o condivisi:

```text
terraform.tfvars
terraform.tfstate
terraform.tfstate.backup
*.tfplan
.terraform/
```

Lo state può contenere informazioni sull'infrastruttura e deve essere trattato come dato sensibile.

---

# PARTE II - ANSIBLE

## 16. Cosa configura Ansible sulla Zeek VM

Il provisioning Ansible della Zeek VM esegue principalmente:

- installazione delle librerie runtime di Zeek;
- installazione di Zeek 8.0.6 da artifact precompilato;
- creazione dell'utente di servizio `zeek`;
- configurazione del PATH;
- configurazione Netplan di `ens19` e `ens19.999`;
- installazione di `node.cfg`, `zeekctl.cfg`, `networks.cfg` e `local.zeek`;
- installazione dei custom script Zeek;
- installazione della policy logrotate;
- installazione del package `bro-simple-scan` tramite `zkg`;
- assegnazione delle capability di packet capture a Zeek;
- configurazione dei servizi systemd per promiscuous mode e Zeek;
- installazione e configurazione del Wazuh Agent;
- configurazione dell'IP del Wazuh Manager;
- hardening finale dell'utente amministrativo della VM.

---

## 17. Prerequisiti Ansible

Servono:

- Ansible installato in Linux/WSL;
- connettività SSH verso la VM;
- la chiave privata corrispondente alla chiave pubblica inserita con Terraform;
- Python 3 nella VM Ubuntu;
- artifact Zeek presente nel progetto;
- connettività Internet dalla VM per installare pacchetti APT e il Wazuh Agent;
- Wazuh Manager raggiungibile dalla VM.

---

## 18. Artifact Zeek richiesto

Il ruolo Zeek si aspetta il file:

```text
ansible/artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.tar.gz
```

Il relativo checksum può essere conservato come:

```text
ansible/artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.sha256
```

Il file `.tar.gz` è molto grande e normalmente non è adatto al normale versionamento GitHub. Chi utilizza il progetto deve procurarsi l'artifact e copiarlo nel percorso atteso, oppure modificare la variabile `zeek_artifact`.

---

## 19. Aggiornare l'inventory dopo Terraform

Il file principale è:

```text
ansible/inventory/lab.yml
```

Esempio:

```yaml
---
all:
  children:

    wazuh_agents:
      children:
        zeek_sensors:

    zeek_sensors:
      hosts:
        zeek01:
          ansible_host: 10.3.10.2
          ansible_user: prova
          ansible_ssh_private_key_file: ~/.ssh/id_ecdsa
```

### `ansible_host`

Deve coincidere con l'IP configurato da Terraform.

Se in `terraform.tfvars` si imposta:

```hcl
ipv4 = "10.3.10.4/24"
```

nell'inventory bisogna usare:

```yaml
ansible_host: 10.3.10.4
```

### `ansible_user`

Deve coincidere con:

```hcl
cloud_init_username
```

configurato in Terraform.

Per esempio:

```hcl
cloud_init_username = "prova"
```

richiede:

```yaml
ansible_user: prova
```

### `ansible_ssh_private_key_file`

Deve puntare alla chiave privata corrispondente alla chiave pubblica installata da Terraform.

Esempio:

```yaml
ansible_ssh_private_key_file: ~/.ssh/id_ecdsa
```

---

## 20. Configurare l'IP del Wazuh Manager

Il file è:

```text
ansible/inventory/group_vars/wazuh_agents.yml
```

Esempio:

```yaml
---
wazuh_manager_address: "10.3.10.3"
```

Questo è il **solo valore da modificare** quando il Wazuh Manager si trova a un indirizzo differente.

Esempio:

```yaml
wazuh_manager_address: "192.168.50.10"
```

Il template dell'agent Wazuh utilizza automaticamente:

```xml
<address>{{ wazuh_manager_address }}</address>
```

---

## 21. Variabili del gruppo Zeek

La configurazione corrente può essere organizzata come:

```text
ansible/inventory/group_vars/zeek_sensors/
+-- main.yml
+-- vault.yml
```

`main.yml` contiene le variabili non sensibili.

Esempio:

```yaml
---
zeek_version: "8.0.6"
zeek_parent_interface: "ens19"
zeek_vlan_id: 999
zeek_capture_interface: "{{ zeek_parent_interface }}.{{ zeek_vlan_id }}"

zeek_artifact: "{{ inventory_dir }}/../artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.tar.gz"

wazuh_agent_config_template: "zeek-agent-ossec.conf.j2"
```

Nella configurazione attuale non è necessario modificare normalmente questi valori quando si ricrea la stessa tipologia di Zeek VM.

---

## 22. Ansible Vault e password sudo

La password amministrativa della VM non viene salvata in Terraform.

Il provisioning utilizza un file Ansible Vault cifrato, per esempio:

```text
ansible/inventory/group_vars/zeek_sensors/vault.yml
```

Il file contiene concettualmente:

```yaml
---
ansible_become_password: "PASSWORD_REALE_UTENTE"
hardening_user_password_hash: '$6$HASH_PASSWORD'
```

### Generare l'hash della password

Da WSL/Linux:

```bash
openssl passwd -6
```

Inserire la password che dovrà essere utilizzata dall'utente della VM con `sudo`.

### Creare il Vault

```bash
EDITOR=nano ansible-vault create ansible/inventory/group_vars/zeek_sensors/vault.yml
```

Ansible chiederà una **Vault password**. Questa è diversa dalla password dell'utente Linux e serve esclusivamente a cifrare/decifrare il Vault.

Dopo la creazione, verificare:

```bash
cat ansible/inventory/group_vars/zeek_sensors/vault.yml
```

L'output deve iniziare con qualcosa simile a:

```text
$ANSIBLE_VAULT;1.1;AES256
```

Non devono comparire password in chiaro.

---

## 23. Hardening finale dell'utente

Durante la creazione iniziale della Cloud Image, l'utente può avere temporaneamente una regola simile a:

```text
prova ALL=(ALL) NOPASSWD:ALL
```

Questo consente ad Ansible di completare il primo provisioning.

Al termine della configurazione, il ruolo `hardening`:

1. assegna la password all'utente;
2. sostituisce la regola `NOPASSWD`;
3. lascia sudo configurato per richiedere la password.

Il ruolo utilizza l'utente definito da:

```yaml
ansible_user
```

quindi non è legato al nome `prova` e può essere riutilizzato su altre VM.

Dopo il provisioning, il comportamento atteso è:

```text
SSH       -> autenticazione con chiave
sudo      -> richiede la password dell'utente
```

Alle esecuzioni Ansible successive, `ansible_become_password` viene recuperata dal Vault.

---

## 24. Nota importante per WSL e `/mnt/c`

Se il progetto è eseguito direttamente sotto un percorso Windows montato in WSL, ad esempio:

```text
/mnt/c/Users/.../wazuh-zeek-terraform-lab
```

Ansible può mostrare:

```text
Ansible is being run in a world writable directory ... ignoring it as an ansible.cfg source
```

In questo caso `ansible.cfg` non viene caricato automaticamente.

Prima di utilizzare i playbook, impostare esplicitamente il percorso dei ruoli:

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
```

E specificare sempre l'inventory nei comandi:

```bash
-i ansible/inventory/lab.yml
```

Alternativamente, copiare il progetto nel filesystem Linux di WSL, per esempio sotto:

```text
~/projects/
```

così Ansible non considera la directory world-writable e può utilizzare normalmente `ansible.cfg`.

---

## 25. Verificare la struttura dell'inventory

Prima del provisioning:

```bash
ansible-inventory -i ansible/inventory/lab.yml --graph
```

Per la Zeek VM ci si aspetta una struttura simile a:

```text
@all:
  |--@wazuh_agents:
  |  |--@zeek_sensors:
  |  |  |--zeek01
  |--@zeek_sensors:
  |  |--zeek01
```

Questo indica che `zeek01` appartiene sia al gruppo `zeek_sensors` sia, tramite il gruppo figlio, a `wazuh_agents`.

---

## 26. Controllare le variabili di una VM

Eseguire:

```bash
ansible-inventory \
  -i ansible/inventory/lab.yml \
  --host zeek01 \
  --ask-vault-pass
```

Verificare che risultino corretti almeno:

```text
ansible_host
ansible_user
wazuh_manager_address
wazuh_agent_config_template
zeek_version
zeek_artifact
zeek_parent_interface
zeek_vlan_id
```

> Non condividere l'output completo se contiene variabili segrete provenienti dal Vault.

---

## 27. Testare la connessione SSH con Ansible

Prima di eseguire i playbook:

```bash
ansible all \
  -i ansible/inventory/lab.yml \
  -m ping
```

Il risultato atteso è:

```text
zeek01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

## 28. Syntax check del playbook

```bash
ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --syntax-check \
  --ask-vault-pass
```

Il risultato atteso è:

```text
playbook: ansible/playbooks/site.yml
```

---

## 29. Eseguire il provisioning Ansible completo

```bash
ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --ask-vault-pass
```

Inserire la Vault password quando richiesta.

Alla fine il recap deve riportare:

```text
unreachable=0
failed=0
```

---

## 30. Cosa esegue `site.yml`

`site.yml` è il punto di ingresso principale del provisioning Ansible.

Attualmente importa il playbook Zeek:

```yaml
---
- import_playbook: zeek.yml
```

In futuro può essere esteso:

```yaml
---
- import_playbook: zeek.yml
- import_playbook: client-linux.yml
- import_playbook: wazuh-manager.yml
```

---

## 31. Ruolo `zeek`

Il ruolo:

```text
ansible/roles/zeek/
```

si occupa esclusivamente della configurazione del sensore Zeek.

Tra le operazioni principali:

```text
installazione artifact Zeek
        |
        +-- /opt/zeek
        |
configurazione Netplan
        |
        +-- ens19
        +-- ens19.999
        |
configurazione Zeek
        |
        +-- node.cfg
        +-- zeekctl.cfg
        +-- networks.cfg
        +-- local.zeek
        +-- custom_scripts/
        |
systemd
        |
        +-- bridge-promisc.service
        +-- vlan-promisc.service
        +-- zeek.service
```

---

## 32. Ruolo `wazuh_agent`

Il ruolo:

```text
ansible/roles/wazuh_agent/
```

è generico e può essere riutilizzato su diverse VM Linux.

Il template da usare viene deciso tramite:

```yaml
wazuh_agent_config_template: "zeek-agent-ossec.conf.j2"
```

Per un futuro client Linux si potrà creare, per esempio:

```text
ansible/roles/wazuh_agent/templates/client-linux-ossec.conf.j2
```

con:

```yaml
wazuh_agent_config_template: "client-linux-ossec.conf.j2"
```

senza modificare il codice principale del ruolo `wazuh_agent`.

---

# PARTE III - WORKFLOW COMPLETO

## 33. Procedura completa per creare una nuova Zeek VM

### Passo 1 - Configurare Terraform

Modificare:

```text
terraform.tfvars
```

Controllare almeno:

```text
Proxmox endpoint
API token
Template VMID
Template node
Datastore
Cloud-Init username
SSH public key
VM name
VMID
CPU
RAM
Disk size
Management IP
Gateway
Bridge/VLAN
```

### Passo 2 - Controllare Terraform

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

### Passo 3 - Creare la VM

```bash
terraform apply
```

### Passo 4 - Aggiornare l'inventory Ansible

Se Terraform ha creato:

```text
10.3.10.4/24
```

modificare:

```text
ansible/inventory/lab.yml
```

con:

```yaml
ansible_host: 10.3.10.4
```

Controllare anche che:

```yaml
ansible_user: prova
```

corrisponda a `cloud_init_username` di Terraform.

### Passo 5 - Configurare il Wazuh Manager

Se necessario modificare:

```text
ansible/inventory/group_vars/wazuh_agents.yml
```

```yaml
wazuh_manager_address: "10.3.10.3"
```

### Passo 6 - Preparare il Vault

Se non esiste ancora:

```bash
openssl passwd -6
```

poi:

```bash
EDITOR=nano ansible-vault create ansible/inventory/group_vars/zeek_sensors/vault.yml
```

### Passo 7 - Se si usa WSL sotto `/mnt/c`, esportare il roles path

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
```

### Passo 8 - Verificare l'inventory

```bash
ansible-inventory -i ansible/inventory/lab.yml --graph
```

### Passo 9 - Verificare SSH

```bash
ansible all -i ansible/inventory/lab.yml -m ping
```

### Passo 10 - Syntax check

```bash
ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --syntax-check \
  --ask-vault-pass
```

### Passo 11 - Eseguire Ansible

```bash
ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --ask-vault-pass
```

---

# PARTE IV - VERIFICHE POST-DEPLOYMENT

## 34. Verificare le interfacce

Entrare nella VM:

```bash
ssh UTENTE@IP_VM
```

Poi:

```bash
ip -br link
```

Verificare la presenza delle interfacce di management e capture, in particolare:

```text
ens19
ens19.999
```

Verificare il promiscuous mode:

```bash
ip link show ens19
ip link show ens19.999
```

Nell'output deve comparire `PROMISC`.

---

## 35. Verificare i servizi

```bash
sudo systemctl status bridge-promisc.service
sudo systemctl status vlan-promisc.service
sudo systemctl status zeek.service
sudo systemctl status wazuh-agent.service
```

I servizi promiscuous `oneshot` possono risultare:

```text
active (exited)
```

Questo è normale.

Zeek e Wazuh Agent devono risultare correttamente avviati.

---

## 36. Verificare Zeek

Versione:

```bash
/opt/zeek/bin/zeek --version
```

Risultato atteso:

```text
zeek version 8.0.6
```

Stato:

```bash
sudo /opt/zeek/bin/zeekctl status
```

Controllo configurazione:

```bash
sudo /opt/zeek/bin/zeekctl check
```

Controllare `node.cfg`:

```bash
cat /opt/zeek/etc/node.cfg
```

Deve puntare alla capture interface:

```text
ens19.999
```

---

## 37. Verificare i custom script Zeek

```bash
find /opt/zeek/share/zeek/site/custom_scripts -type f
```

Controllare anche:

```bash
cat /opt/zeek/share/zeek/site/local.zeek
```

I custom script installati includono le logiche di reverse shell e data exfiltration presenti nel progetto.

---

## 38. Verificare i custom log

```bash
ls -la /var/log/zeek-custom/
```

Tra i log previsti possono esserci:

```text
possible_malware.log
reverse_shell_live.log
reverse_shell_final.log
reverse_shell_movement.log
data_exfiltration.log
```

---

## 39. Verificare Wazuh Agent

Controllare che il template abbia inserito l'indirizzo corretto del Manager:

```bash
grep -A3 '<server>' /var/ossec/etc/ossec.conf
```

Controllare il servizio:

```bash
sudo systemctl status wazuh-agent
```

Controllare i log:

```bash
sudo tail -100 /var/ossec/logs/ossec.log
```

---

## 40. Verificare la password sudo dopo l'hardening

Azzerare la cache sudo:

```bash
sudo -k
```

Poi:

```bash
sudo whoami
```

Il sistema deve chiedere:

```text
[sudo] password for UTENTE:
```

Dopo la password corretta, il risultato deve essere:

```text
root
```

Verificare inoltre che l'utente non abbia più `NOPASSWD`:

```bash
sudo grep -R "NOPASSWD" /etc/sudoers /etc/sudoers.d/
```

---

## 41. Test di idempotenza Ansible

Dopo il primo provisioning, rilanciare lo stesso comando:

```bash
ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --ask-vault-pass
```

Un buon playbook Ansible deve riportare molti task come:

```text
ok
```

anziché modificare continuamente la stessa configurazione.

Il risultato finale deve comunque avere:

```text
failed=0
unreachable=0
```

---

# PARTE V - TROUBLESHOOTING

## 42. `role 'zeek' was not found`

Errore tipico:

```text
ERROR! the role 'zeek' was not found
```

Se il progetto è sotto `/mnt/c`, eseguire:

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
```

Poi rilanciare il playbook.

---

## 43. `No inventory was parsed`

Specificare esplicitamente l'inventory:

```bash
ansible-inventory -i ansible/inventory/lab.yml --graph
```

oppure nei playbook:

```bash
ansible-playbook -i ansible/inventory/lab.yml ...
```

---

## 44. `zeek_artifact is undefined`

Controllare la struttura delle `group_vars`.

La struttura consigliata è:

```text
ansible/inventory/group_vars/zeek_sensors/
+-- main.yml
+-- vault.yml
```

`main.yml` deve contenere:

```yaml
zeek_artifact: "{{ inventory_dir }}/../artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.tar.gz"
```

Controllare inoltre che il file esista realmente nel percorso configurato.

---

## 45. La chiave SSH dell'host è cambiata

Quando Terraform distrugge e ricrea una VM con lo stesso IP, la chiave host SSH cambia.

WSL/Linux può mostrare un errore di host key mismatch.

Rimuovere la vecchia chiave:

```bash
ssh-keygen -f ~/.ssh/known_hosts -R IP_VM
```

Per esempio:

```bash
ssh-keygen -f ~/.ssh/known_hosts -R 10.3.10.2
```

Poi riconnettersi e verificare la nuova fingerprint.

---

## 46. Wazuh Agent è attivo ma non compare sul Manager

Controllare prima:

```bash
sudo tail -100 /var/ossec/logs/ossec.log
```

Verificare la raggiungibilità del Manager e l'enrollment.

Un caso frequente durante i test è il riutilizzo dello stesso nome/IP di una vecchia VM già registrata sul Manager.

Spegnere o distruggere una VM **non elimina automaticamente la sua identità dal Wazuh Manager**.

Se si ricrea un agent con lo stesso nome, verificare la vecchia registrazione sul Manager e gestirla prima del nuovo enrollment.

Per un test diagnostico è possibile utilizzare temporaneamente un IP e un `agent_name` diversi.

---

## 47. Zeek non riceve traffico

Controllare:

```bash
ip link show ens19
ip link show ens19.999
```

Entrambe devono essere attive e configurate correttamente per il promiscuous mode.

Controllare inoltre lato Proxmox/OVS che il traffico mirrored VLAN 999 venga effettivamente inviato alla NIC di capture della Zeek VM.

---

# PARTE VI - AGGIUNGERE ALTRE VM

## 48. Aggiungere una nuova VM con Terraform

Non è necessario creare un nuovo resource Terraform.

Aggiungere una nuova voce in:

```hcl
vms = {
  zeek-tf = {
    ...
  }

  client-linux = {
    vmid = 120
    ...
  }
}
```

Il `for_each` del modulo creerà automaticamente una nuova VM usando lo stesso modulo `modules/proxmox-vm`.

---

## 49. Aggiungere un'altra tipologia di VM ad Ansible

Per esempio un Client Linux può essere aggiunto all'inventory:

```yaml
linux_clients:
  hosts:
    client01:
      ansible_host: 10.3.20.2
      ansible_user: client
      ansible_ssh_private_key_file: ~/.ssh/id_ecdsa
```

Se deve avere Wazuh Agent, il gruppo può essere aggiunto come figlio di:

```yaml
wazuh_agents:
```

Per una configurazione Wazuh diversa da Zeek, creare un nuovo template:

```text
ansible/roles/wazuh_agent/templates/client-linux-ossec.conf.j2
```

poi definire per il gruppo:

```yaml
wazuh_agent_config_template: "client-linux-ossec.conf.j2"
```

Il ruolo `wazuh_agent` rimane lo stesso.

---

# PARTE VII - CHECKLIST RAPIDA

## 50. Prima del deployment

- [ ] Template Ubuntu Cloud-Init presente su Proxmox
- [ ] `qemu-guest-agent` presente nel template
- [ ] API token Proxmox valido
- [ ] `terraform.tfvars` configurato
- [ ] VMID libero
- [ ] IP management libero
- [ ] SSH public key corretta
- [ ] artifact Zeek presente
- [ ] inventory Ansible aggiornato
- [ ] IP Wazuh Manager corretto
- [ ] Vault presente e cifrato

## 51. Comandi essenziali

Terraform:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Ansible:

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"

ansible-inventory -i ansible/inventory/lab.yml --graph

ansible all -i ansible/inventory/lab.yml -m ping

ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --syntax-check \
  --ask-vault-pass

ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --ask-vault-pass
```

## 52. Dopo il deployment

- [ ] VM raggiungibile via SSH
- [ ] `ens19.999` presente
- [ ] `ens19` in promiscuous mode
- [ ] `ens19.999` in promiscuous mode
- [ ] Zeek 8.0.6 installato
- [ ] `zeekctl check` valido
- [ ] `zeek.service` attivo
- [ ] Wazuh Agent attivo
- [ ] Wazuh Agent presente sul Manager
- [ ] custom script Zeek presenti
- [ ] custom log presenti
- [ ] sudo richiede la password dopo l'hardening
- [ ] seconda esecuzione Ansible senza errori

---

## 53. Regola pratica: quale file modificare?

| Cosa vuoi cambiare | File principale |
|---|---|
| Endpoint Proxmox | `terraform.tfvars` |
| API token Proxmox | `terraform.tfvars` |
| Template Proxmox | `terraform.tfvars` |
| Datastore | `terraform.tfvars` |
| Nome VM | chiave nella mappa `vms` in `terraform.tfvars` |
| VMID | `terraform.tfvars` |
| CPU/RAM/disco | `terraform.tfvars` |
| IP Zeek VM | `terraform.tfvars` + `ansible/inventory/lab.yml` |
| Gateway | `terraform.tfvars` |
| VLAN management | `terraform.tfvars` |
| Utente Cloud-Init | `terraform.tfvars` + `ansible/inventory/lab.yml` |
| Chiave SSH pubblica | `terraform.tfvars` |
| Chiave SSH privata usata da Ansible | `ansible/inventory/lab.yml` |
| IP Wazuh Manager | `ansible/inventory/group_vars/wazuh_agents.yml` |
| Versione Zeek | `ansible/inventory/group_vars/zeek_sensors/main.yml` / defaults del ruolo |
| Artifact Zeek | `ansible/inventory/group_vars/zeek_sensors/main.yml` |
| Configurazione Wazuh specifica Zeek | `ansible/roles/wazuh_agent/templates/zeek-agent-ossec.conf.j2` |
| Configurazioni Zeek | `ansible/roles/zeek/files/` e `templates/` |
| Password sudo | `ansible/inventory/group_vars/zeek_sensors/vault.yml` tramite Ansible Vault |

---

## 54. Sequenza consigliata per un nuovo utilizzatore

La sequenza completa più semplice è:

```text
1. Preparare Proxmox e il template Cloud-Init
2. Copiare terraform.tfvars.example -> terraform.tfvars
3. Configurare terraform.tfvars
4. terraform init
5. terraform validate
6. terraform plan
7. terraform apply
8. Aggiornare ansible/inventory/lab.yml con IP e username
9. Configurare wazuh_manager_address
10. Preparare/fornire l'artifact Zeek
11. Preparare il Vault
12. Testare ansible-inventory
13. Testare ansible ping
14. Eseguire syntax-check
15. Eseguire site.yml
16. Verificare Zeek, Wazuh, interfacce e sudo
17. Rilanciare Ansible per verificare l'idempotenza
```

Seguendo questa procedura è possibile ricreare in modo riproducibile la Zeek VM senza effettuare manualmente l'installazione e la configurazione dei singoli componenti.
