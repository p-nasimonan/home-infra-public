# ==========================================
# Ansible Inventory 自動生成
# ==========================================

# Coolify VM のIPアドレスを取得（固定IP）
locals {
  coolify_ip  = "10.0.0.10"  # 固定IP（10.0.0.0/24 内部ネットワーク）
  monaka_node = data.proxmox_virtual_environment_node.monaka
}

# Ansible inventory ファイルを自動生成
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory.ini"

  content = templatefile("${path.module}/ansible/inventory.tpl", {
    coolify_ip = local.coolify_ip
  })

  depends_on = [proxmox_virtual_environment_vm.coolify]
}

# 出力: Ansible 実行時に使用するコマンド
output "ansible_command" {
  description = "Ansible Playbook 実行コマンド"
  value       = "cd ansible && ansible-playbook -i inventory.ini playbook-coolify.yml -v"
}

output "coolify_vm_ip" {
  description = "Coolify VM のIPアドレス（内部ネットワーク 10.0.0.0/24）"
  value       = local.coolify_ip
}

output "monaka_node_info" {
  description = "monaka node の情報"
  value = {
    node_name = data.proxmox_virtual_environment_node.monaka.node_name
  }
}

