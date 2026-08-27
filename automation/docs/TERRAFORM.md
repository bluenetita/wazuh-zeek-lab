# Terraform Guide

## Purpose

Terraform provisions the VM infrastructure on Proxmox. It does not install or configure Zeek or Wazuh inside the guest; that is handled by Ansible.

## Main files

| File | Purpose |
|---|---|
| `versions.tf` | Terraform and provider version requirements |
| `provider.tf` | Proxmox provider configuration |
| `variables.tf` | Root input variable definitions |
| `main.tf` | Instantiates the reusable VM module for every entry in `vms` |
| `outputs.tf` | VM deployment summary |
| `terraform.tfvars.example` | Safe example configuration |
| `terraform.tfvars` | Real environment values; must not be committed |
| `modules/proxmox-vm/` | Reusable Proxmox VM implementation |

## Provider

The project uses:

```text
bpg/proxmox = 0.111.1
```

Terraform requirement:

```text
>= 1.5.0
```

Keep `.terraform.lock.hcl` under version control so all collaborators use the same resolved provider versions.

## Preparing the configuration

Create the local configuration from the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Never put real secrets in `terraform.tfvars.example`.

## Global variables

Typical variables include:

```hcl
proxmox_endpoint   = "https://PROXMOX_IP:8006/"
proxmox_insecure   = true
proxmox_api_token  = "..."

template_vm_id     = 9000
template_node_name = "PROXMOX_NODE"
datastore_id       = "local"

cloud_init_username = "prova"
ssh_public_key      = "ssh-ed25519 AAAA..."
```

### `proxmox_endpoint`

Address of the Proxmox API.

### `proxmox_api_token`

Authentication token used by the provider. It is sensitive and must remain only in the local `terraform.tfvars` or another approved secret-management system.

### `template_vm_id`

VMID of the Ubuntu Cloud-Init template to clone.

### `template_node_name`

Proxmox node hosting the template.

### `datastore_id`

Storage used by the VM clone and Cloud-Init configuration.

### `cloud_init_username`

Linux administrative account created in the guest by Cloud-Init.

The matching Ansible host must use the same account through `ansible_user`.

### `ssh_public_key`

Public SSH key installed by Cloud-Init. Never configure the private key here.

## VM definitions

VMs are declared in the `vms` map.

Example:

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
      ipv4    = "10.3.10.4/24"
      gateway = "10.3.10.1"
    }
  }
}
```

The values above are examples. Use values appropriate for the target lab.

## What to change

| Requirement | Location |
|---|---|
| VM name | key in `vms`, e.g. `zeek-tf` |
| VMID | `vms.<name>.vmid` |
| Proxmox node | `vms.<name>.node_name` |
| CPU cores | `vms.<name>.cores` |
| RAM | `vms.<name>.memory` |
| disk size | `vms.<name>.disk_size` |
| management IP | `vms.<name>.management.ipv4` |
| gateway | `vms.<name>.management.gateway` |
| management VLAN | first item in `networks[].vlan_id` |
| bridge | `networks[].bridge` |
| Cloud-Init user | `cloud_init_username` |
| public SSH key | `ssh_public_key` |
| template VMID | `template_vm_id` |

## Important networking rule for the Zeek VM

For the current capture design:

```text
net0 -> vmbr2 + management VLAN tag
net1 -> vmbr2 without VLAN tag
```

Do not add VLAN 999 to the second Proxmox NIC. Ansible creates `ens19.999` inside the Zeek guest.

## Commands

Initialize providers and modules:

```bash
terraform init
```

Format code:

```bash
terraform fmt -recursive
```

Validate configuration:

```bash
terraform validate
```

Review the plan:

```bash
terraform plan
```

Or save the plan:

```bash
terraform plan -out=prova.tfplan
terraform apply prova.tfplan
```

Apply directly:

```bash
terraform apply
```

Inspect outputs:

```bash
terraform output
```

Destroy managed infrastructure only when intentionally required:

```bash
terraform destroy
```

## Terraform state

Files such as:

```text
terraform.tfstate
terraform.tfstate.backup
```

must not be committed. State may contain infrastructure details and sensitive values even when a Terraform variable is marked `sensitive`.

For a shared/production workflow, use a protected remote backend. For this laboratory, keeping state local and excluded from Git is acceptable as long as collaborators understand that they are not sharing a common Terraform state.

## Adding another VM

Add another map entry under `vms` with a unique name and VMID. Then run:

```bash
terraform plan
terraform apply
```

After Terraform finishes, add the resulting guest to the correct Ansible inventory group. See [ADDING_NEW_VM.md](ADDING_NEW_VM.md).
