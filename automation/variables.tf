variable "proxmox_api_token" {
  description = "API token usato da Terraform per autenticarsi su Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_endpoint" {
  description = "Endpoint HTTPS delle API Proxmox"
  type        = string
}

variable "proxmox_insecure" {
  description = "Disabilita la verifica TLS. Utile in laboratorio con certificato self-signed."
  type        = bool
  default     = true
}

variable "template_vm_id" {
  description = "VMID del template Cloud-Init da clonare"
  type        = number
}

variable "template_node_name" {
  description = "Nodo Proxmox sul quale si trova il template"
  type        = string
}

variable "datastore_id" {
  description = "Datastore usato per il disco Cloud-Init"
  type        = string
}

variable "cloud_init_username" {
  description = "Utente Linux configurato tramite Cloud-Init"
  type        = string
  default     = "sysadmin"
}

variable "ssh_public_key" {
  description = "Chiave SSH pubblica autorizzata sulle VM"
  type        = string
}

variable "vms" {
  description = "Mappa delle VM da creare"

  type = map(object({
    vmid        = number
    node_name   = string
    cores       = number
    memory      = number
    disk_size   = number
    description = optional(string, "Managed by Terraform")
    cpu_type    = optional(string, "x86-64-v2-AES")
    full_clone  = optional(bool, false)
    started     = optional(bool, true)
    on_boot     = optional(bool, true)
    tags        = optional(list(string), [])

    networks = list(object({
      bridge   = string
      vlan_id  = optional(number)
      firewall = optional(bool, false)
      model    = optional(string, "virtio")
      mtu      = optional(number)
    }))

    management = object({
      ipv4    = string
      gateway = optional(string)
    })
  }))
}
