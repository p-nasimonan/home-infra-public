# ==========================================
# Proxmox Data Sources
# ==========================================

# すべてのノード情報を取得
data "proxmox_virtual_environment_nodes" "all_nodes" {}

# 個別ノード情報を取得
data "proxmox_virtual_environment_node" "monaka" {
  node_name = "monaka"
}

data "proxmox_virtual_environment_node" "anko" {
  node_name = "anko"
}

data "proxmox_virtual_environment_node" "aduki" {
  node_name = "aduki"
}

# ノード情報を整理
locals {
  nodes_map = {
    for node in data.proxmox_virtual_environment_nodes.all_nodes.nodes : node.name => {
      name    = node.name
      status  = node.status
      uptime  = node.uptime
    }
  }
}
