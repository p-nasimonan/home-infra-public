# ==========================================
# Cloudflare Tunnel
# ==========================================

# Tunnel用のランダムなシークレットを生成
resource "random_id" "tunnel_secret" {
  byte_length = 32
}

# Cloudflare Tunnelの作成
resource "cloudflare_zero_trust_tunnel_cloudflared" "main" {
  account_id = var.cloudflare_account_id
  name       = "home-tunnel"
  secret     = random_id.tunnel_secret.b64_std
}

# Tunnel設定
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "main" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id

  config {
    # 各サービスへのルーティング設定
    dynamic "ingress_rule" {
      for_each = var.services
      content {
        hostname = "${ingress_rule.value.subdomain}.${var.domain}"
        service  = ingress_rule.value.local_url
        
        # 自己署名証明書対応（Proxmox等）
        origin_request {
          no_tls_verify = true
        }
      }
    }

    # デフォルトルール (必須)
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# ==========================================
# DNS Records for Tunnel
# ==========================================

# 各サービスのCNAMEレコードを作成
resource "cloudflare_record" "tunnel_cnames" {
  for_each = var.services

  zone_id = var.cloudflare_zone_id
  name    = each.value.subdomain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  comment = "Managed by Terraform - ${each.value.description}"
}
