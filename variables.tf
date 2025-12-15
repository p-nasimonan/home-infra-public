# ==========================================
# Proxmox Variables
# ==========================================

variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  sensitive   = true
}

variable "proxmox_token_id" {
  description = "Proxmox API Token ID (format: user@realm!tokenname)"
  type        = string
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

# ==========================================
# SSH Public Key for Cloud-init
# ==========================================

variable "ssh_public_key" {
  description = "SSH public key for youkan user (Cloud-init)"
  type        = string
  default     = ""
}

# ==========================================
# Ubuntu User Password
# ==========================================

variable "ubuntu_password" {
  description = "Ubuntu user password for Cloud-init"
  type        = string
  sensitive   = true
  default     = ""
}

# ==========================================
# Proxmox SSH Private Key
# ==========================================

variable "proxmox_ssh_private_key" {
  description = "Proxmox SSH private key for Terraform provider"
  type        = string
  sensitive   = true
  default     = ""
}

# ==========================================
# VM Common Settings
# ==========================================

variable "k3s_server_defaults" {
  description = "Default settings for K3s server VMs"
  type = object({
    cpu_cores        = number
    cpu_sockets      = number
    memory_mb        = number
    disk_size        = number
    dns_servers      = list(string)
    gateway          = string
    username         = string
    datastore_id     = string
    clone_template   = number
  })
  default = {
    cpu_cores        = 2
    cpu_sockets      = 1
    memory_mb        = 8192
    disk_size        = 32
    dns_servers      = ["192.168.0.30", "1.1.1.1"]
    gateway          = "192.168.0.1"
    username         = "youkan"
    datastore_id     = "local-lvm"
    clone_template   = 9000
  }
}

# ==========================================
# K3s Servers Configuration
# ==========================================

variable "k3s_servers" {
  description = "K3s server VMs configuration"
  type = map(object({
    name       = string
    node_name  = string
    vm_id      = number
    clone_node = string
    ip_address = string
  }))
  default = {
    "server_1" = {
      name       = "k3s-server-1"
      node_name  = "aduki"
      vm_id      = 201
      clone_node = "monaka"
      ip_address = "192.168.0.20"
    }
    "server_2" = {
      name       = "k3s-server-2"
      node_name  = "anko"
      vm_id      = 202
      clone_node = "monaka"
      ip_address = "192.168.0.21"
    }
    "server_3" = {
      name       = "k3s-server-3"
      node_name  = "monaka"
      vm_id      = 203
      clone_node = "monaka"
      ip_address = "192.168.0.22"
    }
  }
}
