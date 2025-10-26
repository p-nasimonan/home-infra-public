# ==========================================
# Proxmox サービス自動公開設定
# ==========================================

# このファイルでは、Proxmox で作成した VM/LXC を
# 自動的に Cloudflare Tunnel 経由で公開する設定を管理します

# 自動公開するサービスの定義
# Proxmox リソースと連携してサービスマップを自動生成
locals {
  # LXC/VM 作成時に自動的にサービスとして登録する
  # 例: 各コンテナの IP とポートから local_url を自動構築
  
  auto_exposed_services = {
    # Proxmox リソースから動的に生成する場合の例:
    # for name, lxc in proxmox_lxc.services : name => {
    #   subdomain   = name
    #   local_url   = "http://${lxc.network[0].ip}:${lxc.port}"
    #   description = "Auto-exposed from Proxmox: ${lxc.hostname}"
    # }
  }
}

# ==========================================
# 使用例: LXC with Auto-Expose
# ==========================================

# 例1: Nextcloud LXC を作成して自動公開
# resource "proxmox_lxc" "nextcloud" {
#   target_node  = var.proxmox_node
#   hostname     = "nextcloud"
#   ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
#   password     = "changeme"
#   unprivileged = true
#   
#   cores  = 2
#   memory = 2048
#   swap   = 512
#   
#   network {
#     name   = "eth0"
#     bridge = "vmbr0"
#     ip     = "192.168.0.101/24"
#     gw     = "192.168.0.1"
#   }
#   
#   rootfs {
#     storage = "local-lvm"
#     size    = "16G"
#   }
#   
#   onboot = true
#   start  = true
#   tags   = "nextcloud,web,auto-expose"
# }
# 
# # 上記 LXC を自動的にサービスとして追加
# locals {
#   nextcloud_service = {
#     subdomain   = "cloud"
#     local_url   = "http://192.168.0.101:80"  # または動的に取得: "${proxmox_lxc.nextcloud.network[0].ip}"
#     description = "Nextcloud - Auto-exposed from Proxmox"
#   }
# }

# ==========================================
# 実装パターン1: 個別サービス定義（推奨）
# ==========================================
# 各サービスを個別に定義し、terraform.tfvars の services に追加する
# この方法が最もシンプルで制御しやすい

# ==========================================
# 実装パターン2: Output経由で自動追加
# ==========================================
# Proxmox module の output を使って、メインの terraform.tfvars を
# 自動更新するスクリプトを作成する

# ==========================================
# 実装パターン3: タグベースの自動検出
# ==========================================
# Proxmox の tags に "expose:subdomain:port" を指定し、
# Terraform でパースして自動的にサービスを追加する

# 例: タグパーサー
# locals {
#   # タグから情報を抽出
#   # tags = "nextcloud,expose:cloud:80,auto"
#   # → subdomain = "cloud", port = "80"
#   
#   parsed_services = {
#     for name, lxc in proxmox_lxc.services :
#     name => {
#       subdomain = regex("expose:([^:]+):", lxc.tags)[0]
#       port      = regex("expose:[^:]+:(\\d+)", lxc.tags)[0]
#     }
#     if can(regex("expose:", lxc.tags))
#   }
# }
