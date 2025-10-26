# ==========================================
# Proxmox 自動公開サービスの例
# ==========================================

# 例1: Nextcloud LXC
resource "proxmox_lxc" "nextcloud" {
  count = 0  # 使用する場合は 1 に変更

  target_node  = var.proxmox_node
  hostname     = "nextcloud"
  ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  password     = "changeme"  # 本番環境では変更すること
  unprivileged = true
  
  cores  = 2
  memory = 2048
  swap   = 512
  
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.0.101/24"
    gw     = "192.168.0.1"
  }
  
  rootfs {
    storage = "local-lvm"
    size    = "16G"
  }
  
  onboot = true
  start  = true
  
  # タグでサービス情報を管理
  tags = "nextcloud,web,managed-by-terraform"
}

# Nextcloud サービスの自動追加
locals {
  # count が 1 の場合のみ追加
  nextcloud_services = var.enable_nextcloud ? {
    nextcloud = {
      subdomain   = "cloud"
      local_url   = "http://192.168.0.101:80"
      description = "Nextcloud - File storage and collaboration"
    }
  } : {}
}

# 例2: Home Assistant LXC
resource "proxmox_lxc" "homeassistant" {
  count = 0  # 使用する場合は 1 に変更

  target_node  = var.proxmox_node
  hostname     = "homeassistant"
  ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  password     = "changeme"
  unprivileged = true
  
  cores  = 2
  memory = 2048
  swap   = 512
  
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.0.102/24"
    gw     = "192.168.0.1"
  }
  
  rootfs {
    storage = "local-lvm"
    size    = "16G"
  }
  
  onboot = true
  start  = true
  tags   = "homeassistant,smart-home,managed-by-terraform"
}

locals {
  homeassistant_services = var.enable_homeassistant ? {
    homeassistant = {
      subdomain   = "home"
      local_url   = "http://192.168.0.102:8123"
      description = "Home Assistant - Smart home automation"
    }
  } : {}
}

# すべての自動サービスをマージ
locals {
  all_proxmox_services = merge(
    local.nextcloud_services,
    local.homeassistant_services
    # 他のサービスもここに追加
  )
}

# 自動サービスを output として公開
output "proxmox_exposed_services" {
  value       = local.all_proxmox_services
  description = "Proxmox から自動公開されるサービス一覧"
}
