# ==========================================
# 自動サービス公開設定
# ==========================================

# Proxmox LXCから自動的にサービスを公開
locals {
  # LXCコンテナの自動検出とサービスマッピング
  proxmox_services = {
    # 例: LXCコンテナ作成時に自動的にサービスを追加
    # for container_name, container in proxmox_lxc.services : container_name => {
    #   subdomain   = container.tags
    #   local_url   = "http://${container.network[0].ip}:${container.port}"
    #   description = "Auto-configured from Proxmox LXC: ${container.hostname}"
    # }
  }

  # 手動サービスと自動サービスをマージ
  all_services = merge(
    var.services,  # terraform.tfvarsで定義した手動サービス
    local.proxmox_services  # Proxmoxから自動検出したサービス
  )
}

# LXCコンテナにタグを使ってサービス情報を埋め込む例
# resource "proxmox_lxc" "auto_service" {
#   target_node  = var.proxmox_node
#   hostname     = "nextcloud"
#   ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
#   password     = "changeme"
#   unprivileged = true
#   
#   cores  = 2
#   memory = 2048
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
#     size    = "8G"
#   }
#   
#   # サービス情報をタグに埋め込む
#   tags = "cloud,nextcloud,port:80"
#   
#   # カスタム変数でサービス公開設定
#   # description = jsonencode({
#   #   cloudflare_subdomain = "cloud"
#   #   service_port         = 80
#   #   auto_expose          = true
#   # })
#   
#   onboot = true
#   start  = true
# }
