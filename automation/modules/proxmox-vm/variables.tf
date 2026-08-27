variable "name" { type = string }
variable "vmid" { type = number }
variable "node_name" { type = string }
variable "description" { type = string }
variable "template_vm_id" { type = number }
variable "template_node_name" { type = string }
variable "datastore_id" { type = string }
variable "cores" { type = number }
variable "memory" { type = number }
variable "cpu_type" { type = string }
variable "full_clone" { type = bool }
variable "started" { type = bool }
variable "on_boot" { type = bool }
variable "tags" { type = list(string) }

variable "networks" {
  type = list(object({
    bridge   = string
    vlan_id  = optional(number)
    firewall = optional(bool, false)
    model    = optional(string, "virtio")
    mtu      = optional(number)
  }))
}

variable "disk_size" {
  description = "Dimensione del disco di sistema in GiB"
  type        = number

  validation {
    condition     = var.disk_size >= 4
    error_message = "disk_size deve essere almeno 4 GiB."
  }
}

variable "management_ip" { type = string }
variable "management_gateway" {
  type    = string
  default = null
}
variable "cloud_init_username" { type = string }
variable "ssh_public_key" { type = string }
