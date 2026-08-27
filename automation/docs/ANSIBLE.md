# Ansible Guide

## Purpose

Ansible configures the operating system after Terraform has created a reachable VM.

The current automation installs and configures a Zeek sensor and its Wazuh Agent, then applies final account hardening.

## Main structure

```text
ansible/
+-- artifacts/
|   +-- zeek-8.0.6/
+-- inventory/
|   +-- lab.yml
|   +-- group_vars/
|       +-- wazuh_agents.yml
|       +-- zeek_sensors/
|           +-- main.yml
|           +-- vault.yml
+-- playbooks/
|   +-- site.yml
|   +-- zeek.yml
+-- roles/
    +-- zeek/
    +-- wazuh_agent/
    +-- hardening/
```

## Inventory

`ansible/inventory/lab.yml` defines hosts and groups.

Example:

```yaml
all:
  children:
    wazuh_agents:
      children:
        zeek_sensors:

    zeek_sensors:
      hosts:
        zeek01:
          ansible_host: 10.3.10.4
          ansible_user: prova
          ansible_ssh_private_key_file: ~/.ssh/id_ecdsa
```

### `ansible_host`

Must match the management address configured by Terraform.

### `ansible_user`

Must match the Cloud-Init username configured for that VM.

The hardening role derives the target administrative username from this variable, so the role remains reusable when different VM types use different usernames.

### `ansible_ssh_private_key_file`

Local path to the private key corresponding to the public key installed by Terraform/Cloud-Init.

The private key must not be stored in this repository.

## Group hierarchy

A Zeek sensor is also a Wazuh Agent. The inventory therefore models `zeek_sensors` as part of the broader `wazuh_agents` group.

This allows common Wazuh variables to be inherited automatically.

## Group variables

### Wazuh agents

`ansible/inventory/group_vars/wazuh_agents.yml` contains shared non-secret Wazuh settings such as:

```yaml
wazuh_manager_address: "10.3.10.3"
```

Change this value if the Wazuh Manager address changes.

### Zeek sensors

Recommended structure:

```text
ansible/inventory/group_vars/zeek_sensors/
+-- main.yml
+-- vault.yml
```

`main.yml` contains non-secret Zeek sensor settings, for example:

```yaml
zeek_version: "8.0.6"
zeek_parent_interface: "ens19"
zeek_vlan_id: 999
zeek_capture_interface: "{{ zeek_parent_interface }}.{{ zeek_vlan_id }}"
zeek_artifact: "{{ inventory_dir }}/../artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.tar.gz"
wazuh_agent_config_template: "zeek-agent-ossec.conf.j2"
```

`vault.yml` contains encrypted secrets.

## Ansible Vault

Create a group Vault directly in encrypted form:

```bash
EDITOR=nano ansible-vault create ansible/inventory/group_vars/zeek_sensors/vault.yml
```

Typical plaintext content before encryption:

```yaml
---
ansible_become_password: "SUDO_PASSWORD"
hardening_user_password_hash: '$6$SHA512_CRYPT_HASH'
```

Generate the password hash with:

```bash
openssl passwd -6
```

After saving, verify that the Vault is encrypted:

```bash
head -n 1 ansible/inventory/group_vars/zeek_sensors/vault.yml
```

Expected:

```text
$ANSIBLE_VAULT;1.1;AES256
```

Never commit the Vault password itself.

## Roles

### `zeek`

The Zeek role:

- installs runtime dependencies;
- installs the precompiled Zeek artifact;
- creates the Zeek service account;
- configures PATH and sudo secure path;
- configures the capture Netplan file;
- deploys `node.cfg`, `zeekctl.cfg`, `networks.cfg` and `local.zeek`;
- deploys custom scripts;
- configures log rotation;
- installs required Zeek packages such as `bro-simple-scan`;
- applies packet capture capabilities;
- installs persistent promiscuous-mode services;
- verifies the installed Zeek version.

### `wazuh_agent`

The Wazuh role:

- installs repository prerequisites;
- imports the Wazuh signing key;
- configures the official repository;
- installs the Wazuh Agent;
- deploys the group-selected configuration template;
- optionally handles the enrollment password;
- optionally holds the package version;
- enables and starts the service.

The role is intentionally generic so future Linux clients can use a different `ossec.conf` template without duplicating the Wazuh Agent installation logic.

### `hardening`

The hardening role is run after functional configuration. It:

- uses `ansible_user` as the user to protect;
- sets the local password from an encrypted hash;
- removes passwordless sudo for that account;
- validates sudoers changes using `visudo`.

This keeps passwords out of Terraform and Terraform state.

## Playbooks

`ansible/playbooks/site.yml` is the main entry point.

It imports the playbooks required by the environment, currently the Zeek sensor playbook.

The Zeek playbook should execute the hardening role only after the Zeek and Wazuh configuration has completed successfully.

## WSL note

When the repository is located under `/mnt/c/...`, Ansible may display:

```text
Ansible is being run in a world writable directory ... ignoring it as an ansible.cfg source
```

Because `ansible.cfg` is ignored in that situation, explicitly configure the role path for the current shell:

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
```

Continue passing the inventory explicitly:

```bash
-i ansible/inventory/lab.yml
```

Moving the repository to the WSL Linux filesystem is another valid long-term solution.

## Pre-flight commands

Display inventory groups:

```bash
ansible-inventory -i ansible/inventory/lab.yml --graph --ask-vault-pass
```

Inspect a host carefully; this command may display secret variables after Vault decryption, so do not share its full output:

```bash
ansible-inventory -i ansible/inventory/lab.yml --host zeek01 --ask-vault-pass
```

Test SSH and Python execution:

```bash
ansible all -i ansible/inventory/lab.yml -m ping --ask-vault-pass
```

Syntax check:

```bash
ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --syntax-check \
  --ask-vault-pass
```

## Run the deployment

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"

ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --ask-vault-pass
```

## Idempotency test

After a successful deployment, run the same playbook again.

A second successful run is important because after hardening, sudo requires the password stored in the encrypted Vault rather than relying on Cloud-Init `NOPASSWD`.

The final recap should have:

```text
failed=0
unreachable=0
```
