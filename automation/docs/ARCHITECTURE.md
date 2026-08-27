# Architecture

## Purpose

This project separates infrastructure provisioning from operating-system configuration:

- **Terraform** manages the Proxmox virtual machine lifecycle.
- **Ansible** configures the operating system and security-monitoring software inside the VM.

This separation keeps the code easier to maintain and allows the same Proxmox module and Ansible roles to be reused for future VM types.

## High-level architecture

```text
                         +----------------------+
                         |      Operator        |
                         | Terraform + Ansible  |
                         +----------+-----------+
                                    |
                     Terraform      |      Ansible/SSH
                                    |
             +----------------------+----------------------+
             |                                             |
             v                                             v
+---------------------------+                 +---------------------------+
|        Proxmox VE         |                 |      Ubuntu 24.04 VM      |
|                           |                 |                           |
| Ubuntu Cloud-Init template| -- clone -----> | Zeek 8.0.6                |
| VM resources              |                 | Wazuh Agent               |
| vmbr2 networking          |                 | systemd services          |
+---------------------------+                 | custom Zeek scripts       |
                                              +-------------+-------------+
                                                            |
                                                            | Wazuh Agent
                                                            v
                                              +---------------------------+
                                              |       Wazuh Manager       |
                                              +---------------------------+
```

## Terraform responsibilities

Terraform creates each VM from the configured Cloud-Init template and controls:

- VM name and VMID;
- target Proxmox node;
- clone mode;
- CPU and RAM;
- system disk size;
- network devices;
- management VLAN;
- management IP and default gateway;
- Cloud-Init username;
- SSH public key;
- VM tags;
- automatic startup.

VM definitions are stored in the `vms` map in `terraform.tfvars`.

## Ansible responsibilities

The Ansible code is organized around groups and reusable roles.

The current Zeek sensor uses:

- `zeek` role;
- `wazuh_agent` role;
- `hardening` role at the end of provisioning.

The generic Wazuh role allows the Wazuh Agent configuration template to be selected according to the inventory group instead of duplicating the installation logic.

## Zeek sensor networking

The Zeek VM has two network interfaces.

### Management interface

The first Proxmox NIC is connected to `vmbr2` with the management VLAN tag. Cloud-Init configures the management address on this interface.

Typical lab example:

```text
Management network: 10.3.10.0/24
Gateway:            10.3.10.1
```

The exact IP is environment-specific and is configured in Terraform and mirrored in the Ansible inventory.

### Capture interface

The second NIC is attached to `vmbr2` without a Proxmox VLAN tag.

It is intentionally used as a raw/trunk capture interface. The guest creates the VLAN subinterface:

```text
ens19
  |
  +-- ens19.999
```

Zeek captures traffic from:

```text
ens19.999
```

The VLAN 999 traffic is expected to arrive from the Proxmox/OVS mirror configuration. The second Proxmox NIC must therefore not be configured with VLAN tag 999 in this design.

## Promiscuous mode

The role installs systemd units that maintain promiscuous mode for the capture interfaces. This makes the configuration persistent across reboots.

## Zeek installation

Zeek 8.0.6 is deployed from a precompiled Ubuntu 24.04 amd64 artifact rather than compiled during every VM deployment.

This makes provisioning significantly faster and deterministic.

The artifact is intentionally excluded from Git because of its size. Its SHA256 checksum remains versioned.

## Wazuh integration

The Zeek VM is also a Wazuh Agent.

The Wazuh Agent role:

1. adds the Wazuh package repository;
2. installs the agent;
3. deploys the group-selected `ossec.conf` template;
4. configures the Wazuh Manager address;
5. optionally handles enrollment credentials;
6. starts and enables `wazuh-agent`.

The manager address is intentionally centralized in:

```text
ansible/inventory/group_vars/wazuh_agents.yml
```

## User access and hardening

Cloud-Init initially creates the administrative account and installs the SSH public key. During the initial bootstrap the account may have passwordless sudo so Ansible can configure the VM.

At the end of provisioning, the hardening role:

1. sets the local password for the Ansible SSH user;
2. changes its sudo rule so sudo requires a password.

The username is derived from `ansible_user`, so the role is not tied to a specific username such as `prova`.

The password and its hash are stored in an encrypted Ansible Vault, not in Terraform.

## Design goals

The architecture is designed around four goals:

- reproducibility;
- separation of responsibilities;
- reusable roles/modules;
- no plaintext secrets in version control.
