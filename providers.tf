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
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.86"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}


# Proxmox Provider (bpg/proxmox for Proxmox VE 9.x support)
provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"
  insecure  = true

  ssh {
    agent       = false
    username    = "terraform"
    private_key = var.proxmox_ssh_private_key
  }
}
