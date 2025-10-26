# ==========================================
# Cloudflare Tunnel Outputs
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
  description = "Cloudflare Tunnel CNAME"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.cname
}

output "service_urls" {
  description = "Public URLs for all services"
  value = {
    for service_key, service in var.services :
    service_key => "https://${service.subdomain}.${var.domain}"
  }
}

# ==========================================
# Proxmox Outputs
# ==========================================

# output "lxc_ip_address" {
#   description = "IP address of LXC container"
#   value       = proxmox_lxc.terraform_runner.network[0].ip
# }

# output "vm_ip_address" {
#   description = "IP address of VM"
#   value       = proxmox_vm_qemu.example_vm.default_ipv4_address
# }

# output "proxmox_nodes" {
#   description = "Available Proxmox nodes"
#   value       = data.proxmox_virtual_environment_nodes.all.names
# }

