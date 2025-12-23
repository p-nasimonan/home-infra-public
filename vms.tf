# ==========================================
# VM/LXC コンテナ定義
# ==========================================
# このファイルでProxmox上のVM/LXCコンテナを管理します
# 各ノードにテンプレートを手動で作成済み:
#   - mochi:  VMID 9000
#   - aduki:  VMID 9001
#   - anko:   VMID 9002
#   - monaka: VMID 9003
# テンプレート VM に youkan ユーザーを事前作成済み

# ==========================================
# K3s クラスタ VM (Control Plane)
# ==========================================
# for_each を使用して共通設定を再利用
# HA構成: etcd, Control Plane, Worker 機能

resource "proxmox_virtual_environment_vm" "k3s_server" {
  for_each = var.k3s_servers

  name        = each.value.name
  description = "${each.value.name} (etcd, Control Plane, Worker - HA)"
  node_name   = each.value.node_name
  vm_id       = each.value.vm_id
  migrate     = true

  clone {
    vm_id     = each.value.clone_template
    full      = false
    node_name = each.value.clone_node
  }

  # Graceful shutdown をサポート（destroy時にqemu-guest-agentでシャットダウン）
  agent {
    enabled = true
  }

  # destroy時にVMを停止させる（graceful shutdown を試みる）
  stop_on_destroy = true

  cpu {
    cores   = var.k3s_server_defaults.cpu_cores
    sockets = var.k3s_server_defaults.cpu_sockets
  }

  memory {
    dedicated = var.k3s_server_defaults.memory_mb
  }

  disk {
    interface    = "scsi0"
    datastore_id = var.k3s_server_defaults.datastore_id
    size         = var.k3s_server_defaults.disk_size
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = var.k3s_server_defaults.datastore_id
    dns {
      servers = var.k3s_server_defaults.dns_servers
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/24"
        gateway = var.k3s_server_defaults.gateway
      }
    }
    user_account {
      username = var.k3s_server_defaults.username
      password = var.ubuntu_password
      keys     = [var.ssh_public_key]
    }
  }

  tags = ["k3s", "server", "etcd", "control-plane", "worker", "ha"]
  
  # destroy時はVMをシャットダウン→60秒待機→強制停止
  lifecycle {
    ignore_changes = []
  }
}

# ==========================================
# K3s Worker Nodes (Minecraft用高スペック)
# ==========================================

resource "proxmox_virtual_environment_vm" "k3s_worker" {
  for_each = var.k3s_workers

  name        = each.value.name
  description = "${each.value.name} (Worker - Minecraft用)"
  node_name   = each.value.node_name
  vm_id       = each.value.vm_id
  migrate     = true

  clone {
    vm_id     = each.value.clone_template
    full      = false
    node_name = each.value.clone_node
  }

  # Graceful shutdown をサポート（destroy時にqemu-guest-agentでシャットダウン）
  agent {
    enabled = true
  }

  # destroy時にVMを停止させる（graceful shutdown を試みる）
  stop_on_destroy = true

  cpu {
    cores   = var.k3s_worker_defaults.cpu_cores
    sockets = var.k3s_worker_defaults.cpu_sockets
  }

  memory {
    dedicated = var.k3s_worker_defaults.memory_mb
  }

  disk {
    interface    = "scsi0"
    datastore_id = var.k3s_worker_defaults.datastore_id
    size         = var.k3s_worker_defaults.disk_size
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = var.k3s_worker_defaults.datastore_id
    dns {
      servers = var.k3s_worker_defaults.dns_servers
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/24"
        gateway = var.k3s_worker_defaults.gateway
      }
    }
    user_account {
      username = var.k3s_worker_defaults.username
      password = var.ubuntu_password
      keys     = [var.ssh_public_key]
    }
  }

  tags = ["k3s", "worker", "minecraft", "high-spec"]
  
  # destroy時はVMをシャットダウン→60秒待機→強制停止
  lifecycle {
    ignore_changes = []
  }
}

# ==========================================
# 注記: AdGuard Home LXC コンテナ
# ==========================================
# bpg/proxmox provider は VM（KVM）のみ対応のため、
# LXC コンテナは Ansible で管理します
#
# 手動作成手順:
#   1. Proxmox UI で AdGuard Home LXC を作成 (VMID: 301)
#   2. IP: 192.168.0.30 を割り当て、ansibleの鍵を設定、ホスト名はadguard-home
#   3. ansible-deploy.yml で playbook-adguard-home-install.yml を実行

# ==========================================
# Outputs
# ==========================================

output "k3s_servers" {
  description = "K3s Server VMs information (Control Plane)"
  value = {
    for key, vm in proxmox_virtual_environment_vm.k3s_server : key => {
      name  = vm.name
      vm_id = vm.vm_id
      node  = vm.node_name
      ip    = var.k3s_servers[key].ip_address
      role  = "control-plane"
    }
  }
}

output "k3s_workers" {
  description = "K3s Worker VMs information (Minecraft用)"
  value = {
    for key, vm in proxmox_virtual_environment_vm.k3s_worker : key => {
      name  = vm.name
      vm_id = vm.vm_id
      node  = vm.node_name
      ip    = var.k3s_workers[key].ip_address
      role  = "worker"
      spec  = "CPU: ${var.k3s_worker_defaults.cpu_cores}コア, RAM: ${var.k3s_worker_defaults.memory_mb}MB"
    }
  }
}

output "adguard_home" {
  description = "AdGuard Home LXC Container (手動作成)"
  value = {
    vmid     = 301
    node     = "aduki"
    ip       = "192.168.0.30"
    web_ui   = "http://192.168.0.30:3000"
    note     = "Terraform では LXC 非対応のため Ansible で管理"
  }
}
