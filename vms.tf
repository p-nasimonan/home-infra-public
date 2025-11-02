# ==========================================
# VM/LXC コンテナ定義
# ==========================================
# このファイルでProxmox上のVM/LXCコンテナを管理します
# サービスの公開設定は terraform.tfvars で行います

# ==========================================
# Infrastructure LXC (常時稼働)
# ==========================================

# Terraform & Cloudflared Runner
resource "proxmox_virtual_environment_container" "terraform_runner" {
  description  = "Terraform and Cloudflared runner"
  node_name    = "anko"
  unprivileged = true

  initialization {
    hostname = "infra-runner"

    user_account {
      password = var.lxc_password
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    # eth1 (services zone): 10.0.0.2/24
    ip_config {
      ipv4 {
        address = "10.0.0.2/24"
        gateway = "10.0.0.1"
      }
    }
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
    type             = "ubuntu"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    size         = 16
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  # Services zone interface (10.0.0.0/24) on vmbr1
  network_interface {
    name   = "eth1"
    bridge = "vmbr1"
  }

  started       = true
  start_on_boot = true

  features {
    nesting = true
  }

  tags = ["terraform", "cloudflared", "infra", "managed"]
}



# ==========================================
# Outputs
# ==========================================

# Terraform Runner の情報を出力
output "terraform_runner_info" {
  description = "Terraform Runner LXC の情報"
  value = {
    vm_id    = proxmox_virtual_environment_container.terraform_runner.vm_id
    hostname = "infra-runner"
    node     = proxmox_virtual_environment_container.terraform_runner.node_name
  }
}
