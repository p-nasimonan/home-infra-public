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
