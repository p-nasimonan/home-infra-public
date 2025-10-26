# ==========================================
# Proxmox Network Configuration
# ==========================================

# 注: Proxmoxのネットワーク設定はノードごとに管理されます
# Terraformでは以下のような設定が可能です:

# 例: ネットワークブリッジの設定
# resource "proxmox_virtual_environment_network_linux_bridge" "vmbr1" {
#   node_name = var.proxmox_node
#   name      = "vmbr1"
#   comment   = "Additional bridge managed by Terraform"
#   
#   address   = "10.0.1.1/24"
#   ports     = ["eth1"]
# }

# 例: VLANの設定
# resource "proxmox_virtual_environment_network_linux_vlan" "vlan100" {
#   node_name = var.proxmox_node
#   name      = "vlan100"
#   comment   = "VLAN 100 managed by Terraform"
#   
#   vlan      = 100
#   interface = "vmbr0"
# }

# データソース: 既存のネットワークインターフェースの情報を取得
# data "proxmox_virtual_environment_nodes" "all" {}

# 注意:
# - Telmate/proxmoxプロバイダーはネットワーク設定の管理機能が限定的です
# - より高度なネットワーク設定が必要な場合は、Ansibleなどと組み合わせることを推奨します
# - または、bpg/proxmoxプロバイダー(proxmox_virtual_environment)の使用も検討してください
