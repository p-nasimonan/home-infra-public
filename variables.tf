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
  description = "Default settings for K3s server VMs (Control Plane)"
  type = object({
    cpu_cores        = number
    cpu_sockets      = number
    memory_mb        = number
    disk_size        = number
    dns_servers      = list(string)
    gateway          = string
    username         = string
    datastore_id     = string
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
  }
}

variable "k3s_worker_defaults" {
  description = "Default settings for K3s worker VMs (Minecraft用)"
  type = object({
    cpu_cores        = number
    cpu_sockets      = number
    memory_mb        = number
    disk_size        = number
    dns_servers      = list(string)
    gateway          = string
    username         = string
    datastore_id     = string
  })
  default = {
    cpu_cores        = 5
    cpu_sockets      = 1
    memory_mb        = 16384
    disk_size        = 64
    dns_servers      = ["192.168.0.30", "1.1.1.1"]
    gateway          = "192.168.0.1"
    username         = "youkan"
    datastore_id     = "local-lvm"
  }
}

# ==========================================
# Template VM IDs per node
# ==========================================

variable "template_vm_ids" {
  description = "Template VM IDs for each Proxmox node"
  type = map(number)
  default = {
    mochi  = 9000
    aduki  = 9001
    anko   = 9002
    monaka = 9003
  }
}

# ==========================================
# K3s Servers Configuration
# ==========================================

variable "k3s_servers" {
  description = "K3s server VMs configuration (Control Plane + Worker)"
  type = map(object({
    name            = string
    node_name       = string
    vm_id           = number
    clone_node      = string
    clone_template  = number
    ip_address      = string
  }))
  default = {
    "server_1" = {
      name            = "k3s-server-1"
      node_name       = "aduki"
      vm_id           = 201
      clone_node      = "aduki"
      clone_template  = 9001
      ip_address      = "192.168.0.20"
    }
    "server_2" = {
      name            = "k3s-server-2"
      node_name       = "anko"
      vm_id           = 202
      clone_node      = "anko"
      clone_template  = 9002
      ip_address      = "192.168.0.21"
    }
    "server_3" = {
      name            = "k3s-server-3"
      node_name       = "mochi"
      vm_id           = 203
      clone_node      = "mochi"
      clone_template  = 9000
      ip_address      = "192.168.0.22"
    }
  }
}

# ==========================================
# K3s Workers Configuration (Minecraft用)
# ==========================================

variable "k3s_workers" {
  description = "K3s worker VMs configuration (Minecraft用高スペック)"
  type = map(object({
    name            = string
    node_name       = string
    vm_id           = number
    clone_node      = string
    clone_template  = number
    ip_address      = string
  }))
  default = {
    "worker_1" = {
      name            = "k3s-worker-1"
      node_name       = "monaka"
      vm_id           = 211
      clone_node      = "monaka"
      clone_template  = 9003
      ip_address      = "192.168.0.23"
    }
    "worker_2" = {
      name            = "k3s-worker-2"
      node_name       = "mochi"
      vm_id           = 212
      clone_node      = "mochi"
      clone_template  = 9000
      ip_address      = "192.168.0.24"
    }
  }
}