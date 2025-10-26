# ==========================================
# Proxmox VMs and LXC Containers
# ==========================================

# 例: LXCコンテナの作成
# resource "proxmox_lxc" "terraform_runner" {
#   target_node  = var.proxmox_node
#   hostname     = "terraform"
#   ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
#   password     = "your_password_here"  # または ssh_public_keys を使用
#   unprivileged = true
#   
#   # リソース設定
#   cores  = 2
#   memory = 2048
#   swap   = 512
#   
#   # ネットワーク設定
#   network {
#     name   = "eth0"
#     bridge = "vmbr0"
#     ip     = "dhcp"
#     ip6    = "auto"
#   }
#   
#   # ストレージ設定
#   rootfs {
#     storage = "local-lvm"
#     size    = "8G"
#   }
#   
#   # 自動起動設定
#   onboot = true
#   start  = true
#   
#   # タグ
#   tags = "terraform,managed"
# }

# 例: VM(仮想マシン)の作成
# resource "proxmox_vm_qemu" "example_vm" {
#   name        = "example-vm"
#   target_node = var.proxmox_node
#   clone       = "ubuntu-cloud-template"  # 事前に作成したテンプレート
#   
#   # リソース設定
#   cores   = 2
#   sockets = 1
#   memory  = 4096
#   
#   # ディスク設定
#   disk {
#     size    = "32G"
#     type    = "scsi"
#     storage = "local-lvm"
#   }
#   
#   # ネットワーク設定
#   network {
#     model  = "virtio"
#     bridge = "vmbr0"
#   }
#   
#   # Cloud-init設定
#   os_type   = "cloud-init"
#   ipconfig0 = "ip=dhcp"
#   
#   # SSH設定
#   # sshkeys = file("~/.ssh/id_rsa.pub")
#   
#   # 自動起動
#   onboot = true
#   
#   # タグ
#   tags = "terraform,managed"
# }

# データソース: 既存のVM/LXCの情報を取得
# data "proxmox_vm_qemu" "existing_vm" {
#   vmid = 100
#   target_node = var.proxmox_node
# }
