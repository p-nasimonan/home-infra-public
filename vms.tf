# ==========================================
# VM/LXC コンテナ定義
# ==========================================
# このファイルでProxmox上のVM/LXCコンテナを管理します
# mochiにテンプレートを手動で作っておく
# テンプレート VM（VMID 9000）に youkan ユーザーを事前作成済み

# ==========================================
# K3s クラスタ VM (HA etcd/Control Plane/Worker)
# ==========================================
# for_each を使用して共通設定を再利用

resource "proxmox_virtual_environment_vm" "k3s_server" {
  for_each = var.k3s_servers

  name        = each.value.name
  description = "${each.value.name} (etcd, Control Plane, Worker - HA)"
  node_name   = each.value.node_name
  vm_id       = each.value.vm_id
  migrate     = true

  clone {
    vm_id     = var.k3s_server_defaults.clone_template
    full      = true
    node_name = each.value.clone_node
  }

  agent {
    enabled = true
  }

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
  description = "K3s Server VMs information"
  value = {
    for key, vm in proxmox_virtual_environment_vm.k3s_server : key => {
      name  = vm.name
      vm_id = vm.vm_id
      node  = vm.node_name
      ip    = var.k3s_servers[key].ip_address
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
