# ==========================================
# メインの設定統合
# ==========================================

# このファイルで Proxmox の自動サービスと手動サービスを統合します

# Proxmox モジュールを読み込む
module "proxmox_services" {
  source = "./proxmox"
  
  # 必要な変数を渡す
  proxmox_api_url     = var.proxmox_api_url
  proxmox_token_id    = var.proxmox_token_id
  proxmox_token_secret = var.proxmox_token_secret
  proxmox_node        = var.proxmox_node
  
  # サービスの有効化フラグ
  enable_nextcloud     = false  # 使用する場合は true に変更
  enable_homeassistant = false  # 使用する場合は true に変更
}

# すべてのサービスを統合
locals {
  # 手動定義のサービス (terraform.tfvars)
  manual_services = var.services
  
  # Proxmox から自動生成されたサービス
  auto_services = try(module.proxmox_services.proxmox_exposed_services, {})
  
  # マージして最終的なサービスリストを作成
  all_services = merge(
    local.manual_services,
    local.auto_services
  )
}

# Cloudflare Tunnel でこのサービスリストを使用
# (tunnel.tf で参照)
output "all_services" {
  value       = local.all_services
  description = "手動 + 自動サービスの統合リスト"
  sensitive   = false
}
