# ==========================================
# Cloudflare Outputs
# ==========================================

output "tunnel_id" {
  description = "Cloudflare Tunnel ID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

output "tunnel_name" {
  description = "Cloudflare Tunnel Name"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.name
}

output "tunnel_token" {
  description = "Cloudflare Tunnel Token for cloudflared"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.tunnel_token
  sensitive   = true
}

output "tunnel_cname" {
  description = "Cloudflare Tunnel CNAME target"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
}

output "service_urls" {
  description = "Public URLs for services"
  value = {
    for service_key, service in var.services :
    service_key => "https://${service.subdomain}.${var.domain}"
  }
}
