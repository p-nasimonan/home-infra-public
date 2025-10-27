terraform {
  required_version = ">= 1.0"
  
  # Terraform Cloud バックエンド
  cloud {
    organization = "p-nasi"
    
    workspaces {
      name = "home-infra"
    }
  }
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73"
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

# Proxmox Provider (bpg/proxmox for Proxmox VE 9.x support)
provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"
  insecure = true
}
