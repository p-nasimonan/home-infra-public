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
      password = "Terraform2024!"
    }
    
    ip_config {
      ipv4 {
        address = "dhcp"
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
  
  started       = true
  start_on_boot = true
  
  features {
    nesting = true
  }
  
  tags = ["terraform", "cloudflared", "infra", "managed"]
}

# ==========================================
# Application LXC (サービスごと)
# ==========================================
# 新しいサービスを追加する場合は、以下のテンプレートをコピーして使用してください

# 例: Nextcloud LXC (コメントアウト - 必要に応じて有効化)
# resource "proxmox_virtual_environment_container" "nextcloud" {
#   description  = "Nextcloud file sharing service"
#   node_name    = "anko"
#   unprivileged = true
#   
#   initialization {
#     hostname = "nextcloud"
#     
#     user_account {
#       password = "changeme"  # 本番環境では必ず変更
#     }
#     
#     ip_config {
#       ipv4 {
#         address = "192.168.0.101/24"
#         gateway = "192.168.0.1"
#       }
#     }
#   }
#   
#   operating_system {
#     template_file_id = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
#     type             = "ubuntu"
#   }
#   
#   cpu {
#     cores = 2
#   }
#   
#   memory {
#     dedicated = 2048
#   }
#   
#   disk {
#     datastore_id = "local-lvm"
#     size         = 16
#   }
#   
#   network_interface {
#     name   = "eth0"
#     bridge = "vmbr0"
#   }
#   
#   started       = true
#   start_on_boot = true
#   
#   tags = ["nextcloud", "web", "managed"]
# }

# 例: Home Assistant LXC (コメントアウト - 必要に応じて有効化)
# resource "proxmox_virtual_environment_container" "homeassistant" {
#   description  = "Home Assistant smart home platform"
#   node_name    = "anko"
#   unprivileged = true
#   
#   initialization {
#     hostname = "homeassistant"
#     
#     user_account {
#       password = "changeme"
#     }
#     
#     ip_config {
#       ipv4 {
#         address = "192.168.0.102/24"
#         gateway = "192.168.0.1"
#       }
#     }
#   }
#   
#   operating_system {
#     template_file_id = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
#     type             = "ubuntu"
#   }
#   
#   cpu {
#     cores = 2
#   }
#   
#   memory {
#     dedicated = 2048
#   }
#   
#   disk {
#     datastore_id = "local-lvm"
#     size         = 16
#   }
#   
#   network_interface {
#     name   = "eth0"
#     bridge = "vmbr0"
#   }
#   
#   started       = true
#   start_on_boot = true
#   
#   tags = ["homeassistant", "smart-home", "managed"]
# }

# ==========================================
# 使い方
# ==========================================
# 1. 上記のテンプレートをコピーしてリソース名を変更
# 2. IPアドレスを割り当て（例: 192.168.0.10x）
# 3. terraform apply -target=proxmox_virtual_environment_container.<name>
# 4. SSH接続してサービスをインストール
# 5. terraform.tfvars の services{} に追加して公開

# ==========================================
# Virtual Machines
# ==========================================

# Coolify PaaS Platform
resource "proxmox_virtual_environment_vm" "coolify" {
  name        = "coolify"
  description = "Coolify - Self-hosted PaaS platform"
  node_name   = "monaka"
  
  agent {
    enabled = true
  }
  
  cpu {
    cores = 2
    type  = "host"
  }
  
  memory {
    dedicated = 4096
  }
  
  # ディスク設定（新規作成）
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 32
    file_format  = "raw"
  }
  
  network_device {
    bridge = "vmbr0"
  }
  
  initialization {
    datastore_id = "local-lvm"
    
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    
    user_account {
      username = "ubuntu"
      password = "Coolify2024!"
      keys     = []
    }
    
    # cloud-init設定ファイルを参照（Proxmox snippets に配置済み）
    user_data_file_id = "local:snippets/coolify-init.yaml"
  }
  
  started       = true
  on_boot       = true
  
  tags = ["coolify", "paas", "docker", "managed"]
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

# Coolify VM の情報を出力
output "coolify_info" {
  description = "Coolify VM の情報"
  value = {
    vm_id    = proxmox_virtual_environment_vm.coolify.vm_id
    name     = proxmox_virtual_environment_vm.coolify.name
    node     = proxmox_virtual_environment_vm.coolify.node_name
    ipv4     = try(proxmox_virtual_environment_vm.coolify.ipv4_addresses[1][0], "DHCP assigned")
  }
}
