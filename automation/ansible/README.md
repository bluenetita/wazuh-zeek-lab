# Ansible Automation

This directory contains the configuration-management layer of the project.

Terraform creates the VM. Ansible configures the operating system and applications inside it.

## Structure

```text
ansible/
+-- artifacts/
|   +-- zeek-8.0.6/
+-- inventory/
|   +-- lab.yml
|   +-- group_vars/
+-- playbooks/
|   +-- site.yml
|   +-- zeek.yml
+-- roles/
    +-- zeek/
    +-- wazuh_agent/
    +-- hardening/
```

## Inventory model

The inventory groups hosts according to function.

Current groups include:

- `zeek_sensors`;
- `wazuh_agents`.

A Zeek sensor is also a Wazuh Agent, so it inherits Wazuh-wide settings.

Future VM types can be added as additional groups such as `linux_clients`.

## Roles

### Zeek

Configures the Zeek sensor, capture interface, custom scripts, capabilities, log rotation and systemd services.

### Wazuh Agent

Generic role that installs the agent and selects an endpoint-specific configuration template via group variables.

### Hardening

Final role used after application provisioning to set the local administrative password and require password-based sudo. The username is derived from `ansible_user` rather than hard-coded.

## Zeek artifact

The binary artifact is expected at:

```text
ansible/artifacts/zeek-8.0.6/zeek-8.0.6-ubuntu24.04-amd64.tar.gz
```

It is excluded from Git. See `artifacts/zeek-8.0.6/README.md`.

## WSL execution

When this repository is used from `/mnt/c/...`, `ansible.cfg` may be ignored because the directory is considered world-writable.

Run:

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
```

and explicitly specify the inventory.

## Validation

```bash
ansible-inventory -i ansible/inventory/lab.yml --graph --ask-vault-pass
ansible all -i ansible/inventory/lab.yml -m ping --ask-vault-pass
ansible-playbook -i ansible/inventory/lab.yml ansible/playbooks/site.yml --syntax-check --ask-vault-pass
```

## Deployment

```bash
ansible-playbook \
  -i ansible/inventory/lab.yml \
  ansible/playbooks/site.yml \
  --ask-vault-pass
```

For detailed documentation, see [`../docs/ANSIBLE.md`](../docs/ANSIBLE.md).
