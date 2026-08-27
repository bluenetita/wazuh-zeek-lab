# Proxmox VM Terraform Module

Reusable Terraform module for creating Cloud-Init virtual machines on Proxmox.

The root module instantiates this module once for every entry in `var.vms`.

## Responsibilities

The module configures:

- VM name and VMID;
- target node;
- clone source/template;
- clone mode;
- CPU and memory;
- system disk;
- QEMU guest agent support;
- one or more network devices;
- Cloud-Init management IPv4 configuration;
- Cloud-Init username;
- SSH public key;
- tags;
- start state and on-boot behavior.

## Example root usage

```hcl
module "vm" {
  source   = "./modules/proxmox-vm"
  for_each = var.vms

  name      = each.key
  vmid      = each.value.vmid
  node_name = each.value.node_name

  template_vm_id     = var.template_vm_id
  template_node_name = var.template_node_name
  datastore_id       = var.datastore_id

  cores     = each.value.cores
  memory    = each.value.memory
  disk_size = each.value.disk_size

  networks = each.value.networks

  management_ip      = each.value.management.ipv4
  management_gateway = try(each.value.management.gateway, null)

  cloud_init_username = var.cloud_init_username
  ssh_public_key      = var.ssh_public_key
}
```

## Inputs

| Variable | Type | Description |
|---|---|---|
| `name` | `string` | VM name |
| `vmid` | `number` | Proxmox VMID |
| `node_name` | `string` | Target Proxmox node |
| `description` | `string` | VM description |
| `template_vm_id` | `number` | Cloud-Init template VMID |
| `template_node_name` | `string` | Node hosting the template |
| `datastore_id` | `string` | Target datastore |
| `cores` | `number` | CPU cores |
| `memory` | `number` | Dedicated RAM in MB |
| `disk_size` | `number` | System disk in GiB; minimum 4 |
| `cpu_type` | `string` | Proxmox/QEMU CPU type |
| `full_clone` | `bool` | Full vs linked clone |
| `started` | `bool` | Start VM after provisioning |
| `on_boot` | `bool` | Start VM automatically with Proxmox |
| `tags` | `list(string)` | Additional VM tags |
| `networks` | `list(object)` | Network device definitions |
| `management_ip` | `string` | Cloud-Init management IPv4 CIDR |
| `management_gateway` | `string` | Default IPv4 gateway |
| `cloud_init_username` | `string` | Cloud-Init administrative username |
| `ssh_public_key` | `string` | Authorized public SSH key |

## Network object

Each network item supports:

```hcl
{
  bridge   = "vmbr2"
  vlan_id  = 10       # optional
  firewall = false    # optional
  model    = "virtio" # optional
  mtu      = 1500     # optional
}
```

## Zeek capture design

The Zeek VM currently uses two devices:

1. management NIC with its VLAN configured by Proxmox;
2. raw capture NIC without VLAN tag.

The VLAN 999 capture subinterface is created inside the guest by Ansible and must not be duplicated as a Proxmox VLAN tag on the second NIC.

## Outputs

The module exposes VM identification information used by the root outputs, including the VM ID and node name.
