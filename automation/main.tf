module "vm" {
  source = "./modules/proxmox-vm"

  for_each = var.vms

  name               = each.key
  vmid               = each.value.vmid
  node_name          = each.value.node_name
  description        = each.value.description
  template_vm_id     = var.template_vm_id
  template_node_name = var.template_node_name
  datastore_id       = var.datastore_id

  cores      = each.value.cores
  memory     = each.value.memory
  disk_size  = each.value.disk_size
  cpu_type   = each.value.cpu_type
  full_clone = each.value.full_clone
  started    = each.value.started
  on_boot    = each.value.on_boot
  tags       = each.value.tags

  networks = each.value.networks

  management_ip      = each.value.management.ipv4
  management_gateway = try(each.value.management.gateway, null)

  cloud_init_username = var.cloud_init_username
  ssh_public_key      = var.ssh_public_key
}
