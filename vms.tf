# ==========================================
# VM/LXC コンテナ定義
# ==========================================
# このファイルでProxmox上のVM/LXCコンテナを管理します
# monakaにテンプレートを手動で作っておく
# テンプレート VM（VMID 9000）に youkan ユーザーを事前作成済み

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
    dedicated = 8192
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
    user_account {
      username = "youkan"
      password = var.ubuntu_password
      keys     = [var.ssh_public_key]
    }
  }

  tags = ["k3s", "server", "etcd", "control-plane", "worker", "ha"]
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
    dedicated = 8192
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
    user_account {
      username = "youkan"
      password = var.ubuntu_password
      keys     = [var.ssh_public_key]
    }
  }

  tags = ["k3s", "server", "etcd", "control-plane", "worker", "ha"]
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
    dedicated = 8192
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
    user_account {
      username = "youkan"
      password = var.ubuntu_password
      keys     = [var.ssh_public_key]
    }
  }

  tags = ["k3s", "server", "etcd", "control-plane", "worker", "ha"]
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
