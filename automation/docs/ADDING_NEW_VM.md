# Adding a New VM

This document describes the recommended workflow for extending the repository with another virtual machine while keeping Terraform and Ansible responsibilities separate.

## 1. Decide the VM type

Examples:

- another Zeek sensor;
- Linux client;
- database server;
- Wazuh Manager;
- another Wazuh-monitored endpoint.

Reuse an existing group when the machine has the same configuration role. Create a new Ansible group only when its configuration is materially different.

## 2. Add the VM to Terraform

Open:

```text
terraform.tfvars
```

Add a new entry to the `vms` map.

Example:

```hcl
vms = {
  zeek-tf = {
    # existing VM
  }

  client-linux-01 = {
    vmid      = 120
    node_name = "bn-pvelab02"

    cores     = 2
    memory    = 4096
    disk_size = 32

    cpu_type   = "x86-64-v2-AES"
    full_clone = false
    started    = true
    on_boot    = true

    description = "Linux client - managed by Terraform"
    tags        = ["linux", "wazuh-agent"]

    networks = [
      {
        bridge   = "vmbr2"
        vlan_id  = 20
        firewall = false
      }
    ]

    management = {
      ipv4    = "10.3.20.10/24"
      gateway = "10.3.20.1"
    }
  }
}
```

Use a unique VMID and an unused IP address.

## 3. Review Terraform changes

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

Check that Terraform plans to create only the intended VM/resources.

Then:

```bash
terraform apply
```

## 4. Add the VM to the Ansible inventory

Add the VM under the appropriate group.

Example:

```yaml
linux_clients:
  hosts:
    client01:
      ansible_host: 10.3.20.10
      ansible_user: client
      ansible_ssh_private_key_file: ~/.ssh/id_ecdsa
```

The Ansible IP must match the Terraform management IP.

The `ansible_user` must match the Cloud-Init user available on that VM.

## 5. Add it to `wazuh_agents` when appropriate

If the VM should run a Wazuh Agent, make its group a child of `wazuh_agents`.

Conceptually:

```yaml
wazuh_agents:
  children:
    zeek_sensors:
    linux_clients:
```

This automatically provides common Wazuh variables such as `wazuh_manager_address`.

## 6. Create group variables

For a new VM category create, for example:

```text
ansible/inventory/group_vars/linux_clients/
+-- main.yml
+-- vault.yml
```

`main.yml` should contain non-secret configuration.

For a generic Wazuh Agent it may select an endpoint-specific template:

```yaml
wazuh_agent_config_template: "client-linux-ossec.conf.j2"
```

## 7. Create the group Vault

If the group uses a different administrative password, create:

```bash
EDITOR=nano ansible-vault create ansible/inventory/group_vars/linux_clients/vault.yml
```

Typical encrypted variables:

```yaml
ansible_become_password: "..."
hardening_user_password_hash: '$6$...'
```

A separate Vault file does not require a separate Vault password. Multiple encrypted group files can use the same Vault password if that matches the security policy for the lab.

## 8. Reuse the generic Wazuh role

Do not create `wazuh_agent_client`, `wazuh_agent_zeek`, etc. unless behavior actually differs.

Prefer:

```text
one generic wazuh_agent role
             |
             +-- Zeek template
             +-- Linux client template
             +-- future server template
```

The group variable selects the correct template.

## 9. Create a role only for unique configuration

For example, a future Linux client may need:

```text
roles/linux_client/
```

A database server may need:

```text
roles/database_server/
```

Keep common configuration in shared roles.

## 10. Add a playbook

Example:

```yaml
---
- name: Configure Linux clients
  hosts: linux_clients
  become: true

  roles:
    - role: linux_client
    - role: wazuh_agent

  post_tasks:
    - name: Apply final VM hardening
      ansible.builtin.include_role:
        name: hardening
```

Then import it from `site.yml`:

```yaml
---
- import_playbook: zeek.yml
- import_playbook: linux-clients.yml
```

## 11. Test before full deployment

```bash
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"

ansible-inventory -i ansible/inventory/lab.yml --graph --ask-vault-pass
ansible all -i ansible/inventory/lab.yml -m ping --ask-vault-pass
ansible-playbook -i ansible/inventory/lab.yml ansible/playbooks/site.yml --syntax-check --ask-vault-pass
```

Then run the deployment.

## Checklist

Before considering the new VM integrated, verify:

- unique Terraform map key;
- unique VMID;
- correct Proxmox node;
- correct management network and gateway;
- Terraform and Ansible management IPs match;
- SSH user exists;
- appropriate inventory group membership;
- correct Wazuh template selected;
- encrypted Vault is available if required;
- `ansible ping` succeeds;
- full playbook succeeds;
- second playbook run succeeds;
- no secret was added to Git.
