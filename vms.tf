# ==========================================
# VM/LXC コンテナ定義
# ==========================================
# このファイルでProxmox上のVM/LXCコンテナを管理します
# monakaにテンプレートを手動で作っておく

# ==========================================
# 共通設定
# ==========================================

locals {
  # cloud-init ユーザーセットアップの共通部分
  k3s_user_setup = <<-SETUP
# ユーザー設定: Ansibleが接続するユーザーの設定
users:
  - name: youkan
    groups: [sudo, docker]
    shell: /bin/bash
    ssh_authorized_keys:
      - ${trimspace(var.ssh_public_key)}
    sudo: ALL=(ALL) NOPASSWD:ALL

# パッケージのインストールとサービス起動
package_update: true
packages:
  - qemu-guest-agent
  - curl

runcmd:
  # タイムゾーンの設定 (JST)
  - timedatectl set-timezone Asia/Tokyo
  # QEMU Guest Agent の自動起動設定と開始
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - swapoff -a
  - sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
SETUP
}

# ==========================================
# Cloud-init User Data 設定ファイル（ホストごと）
# ==========================================
# すべてのK3sノードで共通して実行される初期設定
# - ユーザー: youkan (Ansible接続用)
# - パッケージ: qemu-guest-agent, curl
# - SWAP無効化（K3s必須）
# - タイムゾーン設定（Asia/Tokyo）

# aduki ノード用
resource "proxmox_virtual_environment_file" "k3s_user_config_aduki" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "aduki"

  source_raw {
    file_name = "k3s-user-config.yaml"
    data = <<-EOF
#cloud-config
local-hostname: k3s-server-1
timezone: Asia/Tokyo

${local.k3s_user_setup}
    EOF
  }
}

# anko ノード用
resource "proxmox_virtual_environment_file" "k3s_user_config_anko" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "anko"

  source_raw {
    file_name = "k3s-user-config.yaml"
    data = <<-EOF
#cloud-config
local-hostname: k3s-server-2
timezone: Asia/Tokyo

${local.k3s_user_setup}
    EOF
  }
}

# monaka ノード用
resource "proxmox_virtual_environment_file" "k3s_user_config_monaka" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "monaka"

  source_raw {
    file_name = "k3s-user-config.yaml"
    data = <<-EOF
#cloud-config
local-hostname: k3s-server-3
timezone: Asia/Tokyo

${local.k3s_user_setup}
    EOF
  }
}

# ==========================================
# K3s クラスタ VM (HA etcd/Control Plane/Worker)
# ==========================================

# K3s Server 1 (aduki node)
resource "proxmox_virtual_environment_vm" "k3s_server_1" {
  name        = "k3s-server-1"
  description = "K3s Server 1 (etcd, Control Plane, Worker - HA)"
  node_name   = "aduki"
  vm_id       = 201
  migrate     = true

  clone {
    vm_id     = 9000
    full      = true
    node_name = "monaka"
  }

  agent {
    enabled = true
  }

  cpu {
    cores   = 2
    sockets = 1
  }

  memory {
    dedicated = 6144
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = 32
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "local-lvm"
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
    }
    ip_config {
      ipv4 {
        address = "192.168.0.20/24"
        gateway = "192.168.0.1"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.k3s_user_config_aduki.id
  }

  tags = ["k3s", "server", "etcd", "control-plane", "worker", "ha"]

  depends_on = [
    proxmox_virtual_environment_file.k3s_user_config_aduki
  ]
}

# K3s Server 2 (anko node)
resource "proxmox_virtual_environment_vm" "k3s_server_2" {
  name        = "k3s-server-2"
  description = "K3s Server 2 (etcd, Control Plane, Worker - HA)"
  node_name   = "anko"
  vm_id       = 202
  migrate     = true

  clone {
    vm_id     = 9000
    full      = true
    node_name = "monaka"
  }

  agent {
    enabled = true
  }

  cpu {
    cores   = 2
    sockets = 1
  }

  memory {
    dedicated = 6144
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = 32
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "local-lvm"
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
    }
    ip_config {
      ipv4 {
        address = "192.168.0.21/24"
        gateway = "192.168.0.1"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.k3s_user_config_anko.id
  }

  tags = ["k3s", "server", "etcd", "control-plane", "worker", "ha"]

  depends_on = [
    proxmox_virtual_environment_file.k3s_user_config_anko
  ]
}

# K3s Server 3 (monaka node)
resource "proxmox_virtual_environment_vm" "k3s_server_3" {
  name        = "k3s-server-3"
  description = "K3s Server 3 (etcd, Control Plane, Worker - HA)"
  node_name   = "monaka"
  vm_id       = 203

  clone {
    vm_id     = 9000
    full      = true
    node_name = "monaka"
  }

  agent {
    enabled = true
  }

  cpu {
    cores   = 2
    sockets = 1
  }

  memory {
    dedicated = 6144
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = 32
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "local-lvm"
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
    }
    ip_config {
      ipv4 {
        address = "192.168.0.22/24"
        gateway = "192.168.0.1"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.k3s_user_config_monaka.id
  }

  tags = ["k3s", "server", "etcd", "control-plane", "worker", "ha"]

  depends_on = [
    proxmox_virtual_environment_file.k3s_user_config_monaka
  ]
}

# ==========================================
# Rancher Server VM
# ==========================================

resource "proxmox_virtual_environment_vm" "rancher_server" {
  name        = "rancher-server"
  description = "Rancher Server (K3s Cluster Management UI)"
  node_name   = "monaka"
  vm_id       = 210

  clone {
    vm_id     = 9000
    full      = true
    node_name = "monaka"
  }

  agent {
    enabled = true
  }

  cpu {
    cores   = 2
    sockets = 1
  }

  memory {
    dedicated = 6144
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = 32
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "local-lvm"
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
    }
    ip_config {
      ipv4 {
        address = "192.168.0.30/24"
        gateway = "192.168.0.1"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.k3s_user_config_monaka.id
  }

  tags = ["rancher", "management", "ui"]

  depends_on = [
    proxmox_virtual_environment_file.k3s_user_config_monaka
  ]
}

# ==========================================
# Outputs
# ==========================================

output "k3s_servers" {
  description = "K3s Server VMs information"
  value = {
    k3s_server_1 = {
      name  = proxmox_virtual_environment_vm.k3s_server_1.name
      vm_id = proxmox_virtual_environment_vm.k3s_server_1.vm_id
      node  = proxmox_virtual_environment_vm.k3s_server_1.node_name
      ip    = "192.168.0.20"
    }
    k3s_server_2 = {
      name  = proxmox_virtual_environment_vm.k3s_server_2.name
      vm_id = proxmox_virtual_environment_vm.k3s_server_2.vm_id
      node  = proxmox_virtual_environment_vm.k3s_server_2.node_name
      ip    = "192.168.0.21"
    }
    k3s_server_3 = {
      name  = proxmox_virtual_environment_vm.k3s_server_3.name
      vm_id = proxmox_virtual_environment_vm.k3s_server_3.vm_id
      node  = proxmox_virtual_environment_vm.k3s_server_3.node_name
      ip    = "192.168.0.22"
    }
  }
}

output "rancher_server" {
  description = "Rancher Server VM information"
  value = {
    name  = proxmox_virtual_environment_vm.rancher_server.name
    vm_id = proxmox_virtual_environment_vm.rancher_server.vm_id
    node  = proxmox_virtual_environment_vm.rancher_server.node_name
    ip    = "192.168.0.30"
  }
}

