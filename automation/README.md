# Wazuh-Zeek Terraform Lab

Infrastructure-as-Code project for provisioning a Zeek sensor VM on Proxmox with **Terraform** and configuring it with **Ansible**.

The current implementation automates the lifecycle from the creation of an Ubuntu Cloud-Init VM to the installation and configuration of Zeek and the Wazuh Agent.

## What the project does

### Terraform

Terraform is responsible for the infrastructure layer:

- clones an Ubuntu 24.04 Cloud-Init template on Proxmox;
- configures VMID, node, CPU, RAM and disk size;
- creates the required network interfaces;
- configures the management IP and gateway;
- creates the Cloud-Init administrative user;
- installs the SSH public key;
- starts the VM and enables start-on-boot.

### Ansible

Ansible is responsible for guest configuration:

- configures the Zeek capture interface and VLAN subinterface;
- installs Zeek 8.0.6 from a precompiled artifact;
- installs custom Zeek configuration and detection scripts;
- configures promiscuous mode and systemd services;
- installs and configures the Wazuh Agent;
- points the Wazuh Agent to the selected Wazuh Manager;
- applies final user hardening, including password-protected sudo;
- supports encrypted secrets through Ansible Vault.

## Deployment flow

```text
Terraform
    |
    v
Proxmox VM
Ubuntu 24.04 Cloud-Init
    |
    | SSH key
    v
Ansible
    |
    +-- Zeek
    +-- capture interface / VLAN 999
    +-- custom detection scripts
    +-- Wazuh Agent
    +-- systemd services
    +-- final user hardening
    |
    v
Ready Zeek sensor
```

## Repository structure

```text
wazuh-zeek-terraform-lab/
|
+-- README.md
+-- DEPLOYMENT_GUIDE.md
+-- CHANGELOG.md
+-- CONTRIBUTING.md
+-- SECURITY.md
+-- .gitignore
+-- .terraform.lock.hcl
+-- main.tf
+-- provider.tf
+-- variables.tf
+-- outputs.tf
+-- versions.tf
+-- terraform.tfvars.example
+-- ansible.cfg
+-- docs/
|   +-- ARCHITECTURE.md
|   +-- TERRAFORM.md
|   +-- ANSIBLE.md
|   +-- ADDING_NEW_VM.md
|   +-- TROUBLESHOOTING.md
|   +-- REPOSITORY_SETUP.md
+-- modules/
|   +-- proxmox-vm/
|       +-- README.md
|       +-- main.tf
|       +-- variables.tf
|       +-- outputs.tf
|       +-- versions.tf
+-- ansible/
    +-- README.md
    +-- artifacts/
    +-- inventory/
    +-- playbooks/
    +-- roles/
```

## Quick start

1. Prepare the Proxmox Ubuntu Cloud-Init template.
2. Copy the Terraform example variables:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Edit `terraform.tfvars` with the Proxmox endpoint, API token, VMID, VM resources, management IP and SSH public key.
4. Run Terraform:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

5. Update `ansible/inventory/lab.yml` with the IP and SSH user created by Cloud-Init.
6. Configure the Wazuh Manager address in `ansible/inventory/group_vars/wazuh_agents.yml`.
7. Place the Zeek artifact in `ansible/artifacts/zeek-8.0.6/`.
8. Prepare the encrypted Ansible Vault used by the target VM group.
9. Run Ansible:

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
ansible-playbook -i ansible/inventory/lab.yml ansible/playbooks/site.yml --ask-vault-pass
```

For the complete procedure, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

## Documentation

- [Deployment Guide](DEPLOYMENT_GUIDE.md) - complete deployment procedure.
- [Architecture](docs/ARCHITECTURE.md) - component responsibilities and network design.
- [Terraform](docs/TERRAFORM.md) - Terraform variables, VM configuration and commands.
- [Ansible](docs/ANSIBLE.md) - inventory, groups, roles, Vault and execution flow.
- [Adding a new VM](docs/ADDING_NEW_VM.md) - how to extend the project to other VM types.
- [Troubleshooting](docs/TROUBLESHOOTING.md) - common errors and fixes.
- [Repository Setup](docs/REPOSITORY_SETUP.md) - safe Git/GitHub publication procedure.
- [Security](SECURITY.md) - secrets and repository security rules.
- [Contributing](CONTRIBUTING.md) - collaboration workflow.

## Security

Do not commit plaintext secrets even when the repository is private.

In particular, do not version:

- `terraform.tfvars`;
- Terraform state files;
- Proxmox API tokens;
- SSH private keys;
- Ansible Vault passwords;
- Wazuh `authd.pass` or `client.keys`;
- unencrypted credentials;
- the large Zeek binary artifact.

Encrypted Ansible Vault files may be committed as long as they are actually encrypted and the Vault password is distributed through a separate secure channel.

See [SECURITY.md](SECURITY.md) for details.

## Current scope

The current deployment targets a Zeek sensor. The structure is intentionally designed so that additional groups such as Linux clients, database servers or other Wazuh agents can be added later without duplicating the common automation logic.
