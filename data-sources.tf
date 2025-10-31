# ==========================================
# Proxmox Data Sources
# ==========================================

# monaka node の情報を取得
data "proxmox_virtual_environment_node" "monaka" {
  node_name = "monaka"
}

