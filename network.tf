# ==========================================
# Proxmox Network Configuration
# ==========================================

# Isolated Network Bridge (10.0.0.0/24)
# 注: vmbr1 ブリッジは network_zones.tf で定義・管理しています
# このファイルでは削除しました（重複定義を避けるため）
# Note: Proxmox firewall rules need to be configured at multiple levels:
# 1. Datacenter level
# 2. Node level  
# 3. VM/Container level

# Create security group for isolated network access
resource "proxmox_virtual_environment_cluster_firewall_security_group" "isolated_net_access" {
  name    = "isolated-net"  # 短くした（18文字以下）
  comment = "Allow access to 10.0.0.0/24 from 192.168.1.0/24 only"

  rule {
    type    = "in"
    action  = "ACCEPT"
    comment = "Allow from home network (192.168.1.0/24)"
    source  = "192.168.1.0/24"
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
