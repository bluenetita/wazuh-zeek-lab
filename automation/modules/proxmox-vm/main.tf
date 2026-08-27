resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  vm_id       = var.vmid
  node_name   = var.node_name
  description = var.description

  started = var.started
  on_boot = var.on_boot

  stop_on_destroy = true

  tags = distinct(concat(["terraform"], var.tags))

  clone {
    vm_id        = var.template_vm_id
    node_name    = var.template_node_name
    datastore_id = var.datastore_id
    full         = var.full_clone
    retries      = 3
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = "raw"
    iothread     = true
  }

  serial_device {
    device = "socket"
  }

  cpu {
    cores = var.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  agent {
    enabled = true

    wait_for_ip {
      ipv4 = true
    }
  }

  dynamic "network_device" {
    for_each = var.networks

    content {
      bridge   = network_device.value.bridge
      model    = network_device.value.model
      vlan_id  = try(network_device.value.vlan_id, null)
      firewall = try(network_device.value.firewall, false)
      mtu      = try(network_device.value.mtu, null)
    }
  }

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.management_ip
        gateway = var.management_gateway
      }
    }

    user_account {
      username = var.cloud_init_username
      keys     = [trimspace(var.ssh_public_key)]
    }
  }
}
