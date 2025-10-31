# ==========================================
# Cloudflare Variables
# ==========================================

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  default     = "acc095ded86d09a40f207b437ae5f2de"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for youkan.uk"
  type        = string
  default     = "97303f6fe58acada4bd8e806172ddb2f"
}

variable "domain" {
  description = "Root domain name"
  type        = string
  default     = "youkan.uk"
}

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
  default     = "aduki"  # または "monaka" または "anko"
}

# ==========================================
# Service Variables
# ==========================================

variable "services" {
  description = "Map of services to expose via Cloudflare Tunnel"
  type = map(object({
    subdomain   = string
    local_url   = string
    description = string
  }))
  default = {
    proxmox = {
      subdomain   = "pve"
      local_url   = "https://192.168.0.13:8006"
      description = "Proxmox VE Console"
    }
    # 追加のサービス例:
    # "homeassistant" = {
    #   subdomain   = "home"
    #   local_url   = "http://192.168.0.100:8123"
    #   description = "Home Assistant"
    # }
    # "nextcloud" = {
    #   subdomain   = "cloud"
    #   local_url   = "http://192.168.0.101:80"
    #   description = "Nextcloud"
    # }
  }
}
