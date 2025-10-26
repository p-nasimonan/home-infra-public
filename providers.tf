terraform {
  required_version = ">= 1.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.0"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Cloudflare Provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Proxmox Provider
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = true  # 自己署名証明書を使用している場合
  
  # ログレベル (デバッグ時に使用)
  # pm_log_enable = true
  # pm_log_file   = "terraform-plugin-proxmox.log"
  # pm_log_levels = {
  #   _default    = "debug"
  #   _capturelog = ""
  # }
}
