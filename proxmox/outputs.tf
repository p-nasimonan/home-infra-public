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
