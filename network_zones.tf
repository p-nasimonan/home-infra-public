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

# anko ノードに vmbr1 を自動作成
# aduki, monaka ノードにも vmbr1 を自動作成
resource "proxmox_virtual_environment_network_linux_bridge" "vmbr1_anko" {
  name       = "vmbr1"
  node_name  = "anko"
  address    = "10.0.0.1/24"
  autostart  = true
  comment    = "Isolated network for services (10.0.0.0/24) - Managed by Terraform"
}

resource "proxmox_virtual_environment_network_linux_bridge" "vmbr1_monaka" {
  name       = "vmbr1"
  node_name  = "monaka"
  address    = "10.0.0.1/24"
  autostart  = true
  comment    = "Isolated network for services (10.0.0.0/24) - Managed by Terraform"
}

resource "proxmox_virtual_environment_network_linux_bridge" "vmbr1_aduki" {
  name       = "vmbr1"
  node_name  = "aduki"
  address    = "10.0.0.1/24"
  autostart  = true
  comment    = "Isolated network for services (10.0.0.0/24) - Managed by Terraform"
}

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

output "vmbr1_bridges" {
  description = "vmbr1 ブリッジ管理状態"
  value = {
    anko = {
      status      = "Terraform managed"
      node        = "anko"
      address     = proxmox_virtual_environment_network_linux_bridge.vmbr1_anko.address
      created     = "Automatically via Terraform"
    }
    monaka = {
      status      = "Terraform managed"
      node        = "monaka"
      address     = proxmox_virtual_environment_network_linux_bridge.vmbr1_monaka.address
      created     = "Automatically via Terraform"
    }
    aduki = {
      status      = "Terraform managed"
      node        = "aduki"
      address     = proxmox_virtual_environment_network_linux_bridge.vmbr1_aduki.address
      created     = "Automatically via Terraform"
    }
  }
}
