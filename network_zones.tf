# ==========================================
# ネットワークゾーン設定
# ==========================================
# Proxmox では Zone (Simple) を使用してネットワークセグメントを管理します
# Zone は Proxmox WebUI から手動で作成し、Terraform で参照します

locals {
  zones = {
    # デフォルトゾーン（管理ネットワーク）
    default = {
      name        = "default"
      bridge      = "vmbr0"
      network     = "192.168.0.0/24"
      gateway     = "192.168.0.1"
      description = "Management and infrastructure network"
    }
    
    # サービスゾーン（隔離ネットワーク）
    services = {
      name        = "services"
      bridge      = "vmbr1"
      network     = "10.0.0.0/24"
      gateway     = "10.0.0.1"
      description = "Isolated services network (Coolify, Apps)"
    }
  }
  
  # Zone 作成フラグ（手動作成の場合は false）
  auto_create_zones = false
}

# ==========================================
# Zone 自動作成（Proxmox API 経由）
# ==========================================
# 注: var.proxmox_api_url, var.proxmox_token_id, var.proxmox_token_secret が必要

# サービスゾーン自動作成（オプション）
resource "null_resource" "create_services_zone" {
  count = local.auto_create_zones ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      curl -k -X POST \
        -H "Authorization: PVEAPIToken=${var.proxmox_token_id}=${var.proxmox_token_secret}" \
        -H "Content-Type: application/json" \
        -d '{
          "zone": "${local.zones.services.name}",
          "description": "${local.zones.services.description}",
          "type": "simple"
        }' \
        https://${replace(var.proxmox_api_url, ":8006", "")}/api2/json/access/zones 2>/dev/null || echo "Zone already exists or creation skipped"
    EOT
  }
}

# ==========================================
# ネットワークブリッジ定義
# ==========================================

# 注: ブリッジ自体の作成は Proxmox ホストで手動で行う必要があります
# Terraform では参照と割り当てのみ行います

# vmbr1 (Services Network) の作成スクリプト例：
# /etc/network/interfaces に以下を追加
# auto vmbr1
# iface vmbr1 inet static
#     address 10.0.0.1
#     netmask 255.255.255.0
#     bridge-ports none
#     bridge-stp off
#     bridge-fd 0

# ==========================================
# ゾーン参照用の出力
# ==========================================

output "network_zones" {
  description = "ネットワークゾーン設定"
  value       = local.zones
}

output "services_zone_config" {
  description = "サービスゾーン（10.0.0.0/24）の設定"
  value = {
    name        = local.zones.services.name
    bridge      = local.zones.services.bridge
    network     = local.zones.services.network
    gateway     = local.zones.services.gateway
    description = local.zones.services.description
  }
}

output "nat_gateway_config" {
  description = "NAT Gateway の設定（サービスゾーンのゲートウェイ）"
  value = {
    network      = local.zones.services.network
    gateway_ip   = local.zones.services.gateway
    gateway_host = "nat-gateway (LXC on anko node)"
  }
}
