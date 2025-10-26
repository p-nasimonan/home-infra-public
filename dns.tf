# ==========================================
# Additional DNS Records
# ==========================================

# 必要に応じて追加のDNSレコードをここに定義

# 例: ルートドメインのAレコード
# resource "cloudflare_record" "root" {
#   zone_id = var.cloudflare_zone_id
#   name    = "@"
#   content = "192.0.2.1"
#   type    = "A"
#   proxied = true
#   comment = "Managed by Terraform"
# }

# 例: MXレコード
# resource "cloudflare_record" "mx" {
#   zone_id  = var.cloudflare_zone_id
#   name     = "@"
#   content  = "mail.youkan.uk"
#   type     = "MX"
#   priority = 10
#   comment  = "Managed by Terraform"
# }

# 例: TXTレコード (SPF, DKIM, DMARCなど)
# resource "cloudflare_record" "spf" {
#   zone_id = var.cloudflare_zone_id
#   name    = "@"
#   content = "v=spf1 include:_spf.example.com ~all"
#   type    = "TXT"
#   comment = "Managed by Terraform - SPF record"
# }
