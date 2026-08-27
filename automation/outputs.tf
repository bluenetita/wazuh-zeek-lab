output "virtual_machines" {
  description = "Riepilogo delle VM create"

  value = {
    for name, vm in module.vm :
    name => {
      vm_id         = vm.vm_id
      node_name     = vm.node_name
      management_ip = var.vms[name].management.ipv4
    }
  }
}
