# ==========================================
# VM/LXC コンテナ定義
# ==========================================
# このファイルでProxmox上のVM/LXCコンテナを管理します

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
    node_name = "monaka" # テンプレートは monaka ノードにある
  }

  agent {
    enabled = true # Proxmox VM agent 有効化
  }

  cpu {
    cores   = 2
    sockets = 1
  }

  memory {
    dedicated = 6144 # 6GB
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = 32 # GB
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "local"
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
    }
    ip_config {
      ipv4 {
        address = "192.168.0.20/24"
        gateway = "192.168.0.1"
      }
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
    node_name = "monaka" # テンプレートは monaka ノードにある
  }

  agent {
    enabled = true # Proxmox VM agent 有効化
  }

  cpu {
    cores   = 2
    sockets = 1
  }

  memory {
    dedicated = 6144 # 6GB
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = 32 # GB
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "local"
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
    }
    ip_config {
      ipv4 {
        address = "192.168.0.21/24"
        gateway = "192.168.0.1"
      }
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
  migrate     = true

  clone {
    vm_id     = 9000
    full      = true
    node_name = "monaka" # テンプレートは monaka ノードにある
  }

  agent {
    enabled = true # Proxmox VM agent 有効化
  }

  cpu {
    cores   = 2
    sockets = 1
  }

  memory {
    dedicated = 6144 # 6GB
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = 32 # GB
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "local"
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
    }
    ip_config {
      ipv4 {
        address = "192.168.0.22/24"
        gateway = "192.168.0.1"
      }
    }
  }

  tags = ["k3s", "server", "etcd", "control-plane", "worker", "ha"]
}

# ==========================================
# Rancher Server VM
# ==========================================

# Rancher Server (monaka node)
resource "proxmox_virtual_environment_vm" "rancher_server" {
  name        = "rancher-server"
  description = "Rancher Server (K3s Cluster Management UI)"
  node_name   = "monaka"
  vm_id       = 210
  migrate     = true

  clone {
    vm_id     = 9000
    full      = true
    node_name = "monaka" # テンプレートは monaka ノードにある
  }

  agent {
    enabled = true # Proxmox VM agent 有効化
  }

  cpu {
    cores   = 2
    sockets = 1
  }

  memory {
    dedicated = 6144 # 6GB
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = 32 # GB
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "local"
    dns {
      servers = ["8.8.8.8", "8.8.4.4"]
    }
    ip_config {
      ipv4 {
        address = "192.168.0.30/24"
        gateway = "192.168.0.1"
      }
    }
  }

  tags = ["rancher", "management", "ui"]
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

