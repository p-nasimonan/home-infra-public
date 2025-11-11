# ==========================================
# Proxmox Variables
# ==========================================

variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.0.13:8006/api2/json"
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

variable "proxmox_node" {
  description = "Default Proxmox node to use"
  type        = string
  default     = "aduki" # または "monaka" または "anko"
}

# ==========================================
# Container / VM Passwords
# ==========================================

variable "lxc_password" {
  description = "LXC password"
  type        = string
  sensitive   = true
}

# ==========================================
# SSH Public Key for Cloud-init
# ==========================================

variable "ssh_public_key" {
  description = "SSH public key for ubuntu user (Cloud-init)"
  type        = string
  default     = ""
}
