# ==========================================
# Proxmox Network Configuration
# ==========================================

# Isolated Network Bridge (10.0.0.0/24)
# This network is isolated and only accessible from 192.168.1.0/24
# 
# NOTE: vmbr1 は手動で作成済み（Proxmox ホストの /etc/network/interfaces で設定）
# 以下のリソース定義はコメントアウト（Terraform で管理しない）
# 
# resource "proxmox_virtual_environment_network_linux_bridge" "vmbr1" {
#   node_name = "anko"
#   name      = "vmbr1"
#   comment   = "Isolated network for services (10.0.0.0/24) - Managed by Terraform"
#
#   address   = "10.0.0.1/24"
#   autostart = true
# }

# Firewall configuration for the isolated network
# Note: Proxmox firewall rules need to be configured at multiple levels:
# 1. Datacenter level
# 2. Node level  
# 3. VM/Container level

# Create security group for isolated network access
resource "proxmox_virtual_environment_cluster_firewall_security_group" "isolated_net_access" {
  name    = "isolated-net-access"
  comment = "Allow access to 10.0.0.0/24 from 192.168.1.0/24 only"

  rule {
    type    = "in"
    action  = "ACCEPT"
    comment = "Allow from home network (192.168.1.0/24)"
    source  = "192.168.1.0/24"
    iface   = "net1"
    log     = "info"
  }

  rule {
    type    = "in"
    action  = "DROP"
    comment = "Drop all other traffic to isolated network"
    log     = "info"
  }
}

# Note: For complete isolation, you should also:
# 1. Enable firewall at datacenter level
# 2. Apply security group to VMs/containers on vmbr1
# 3. Consider using iptables/nftables for additional filtering
