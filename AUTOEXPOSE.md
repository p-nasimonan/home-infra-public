# 🚀 Proxmox サービス自動公開ガイド

Proxmox で作成した VM/LXC を自動的に Cloudflare Tunnel 経由で公開する方法を説明します。

## 📚 概要

### Cloudflare Tunnel の仕組み

```
インターネット
    ↓
https://cloud.youkan.uk (Cloudflare DNS)
    ↓
Cloudflare Edge (Tunnel経由)
    ↓
cloudflared エージェント (ローカル環境で実行)
    ↓
http://192.168.0.101:80 (Proxmox LXC内のNextcloud)
```

### `local_url` とは？

`local_url = "http://192.168.0.101:80"` は以下を指します:
- `192.168.0.101` = Proxmox で作成した LXC/VM のローカル IP アドレス
- `80` = コンテナ内で動いているサービスのポート番号
- cloudflared エージェントから **アクセス可能** なローカルネットワーク上のアドレス

## 🎯 実装方法

### 方法1: 手動設定（シンプル・推奨）

**ステップ1:** Proxmox で LXC を作成

```hcl
# proxmox/vms.tf
resource "proxmox_lxc" "nextcloud" {
  target_node  = "aduki"
  hostname     = "nextcloud"
  ostemplate   = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  
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
}
```

**ステップ2:** `terraform.tfvars` にサービスを追加

```hcl
services = {
  "nextcloud" = {
    subdomain   = "cloud"
    local_url   = "http://192.168.0.101:80"
    description = "Nextcloud"
  }
}
```

**ステップ3:** Terraform 適用

```powershell
terraform plan
terraform apply
```

---

### 方法2: 半自動化（変数制御）

**ステップ1:** `variables.tf` に有効化フラグを追加

```hcl
variable "enable_nextcloud" {
  description = "Nextcloud サービスを有効化"
  type        = bool
  default     = false
}
```

**ステップ2:** `proxmox/example_services.tf` で条件付きリソース

```hcl
resource "proxmox_lxc" "nextcloud" {
  count = var.enable_nextcloud ? 1 : 0
  
  target_node = var.proxmox_node
  hostname    = "nextcloud"
  # ... 設定 ...
  
  network {
    ip = "192.168.0.101/24"
  }
}

locals {
  nextcloud_services = var.enable_nextcloud ? {
    nextcloud = {
      subdomain   = "cloud"
      local_url   = "http://192.168.0.101:80"
      description = "Nextcloud"
    }
  } : {}
}
```

**ステップ3:** `terraform.tfvars` で有効化

```hcl
enable_nextcloud = true
```

**ステップ4:** Terraform 適用

```powershell
terraform apply
```

→ LXC とサービス公開が同時に作成される

---

### 方法3: 完全自動化（タグベース）※高度

**概念:**
Proxmox の tags に `expose:subdomain:port` を指定し、Terraform で自動検出

```hcl
resource "proxmox_lxc" "auto_service" {
  hostname = "myapp"
  tags     = "myapp,expose:myapp:3000,auto"
  
  network {
    ip = "192.168.0.150/24"
  }
}

# タグからサービス情報を自動抽出
locals {
  auto_services = {
    for name, lxc in proxmox_lxc.auto_service :
    name => {
      subdomain = regex("expose:([^:]+):", lxc.tags)[0]
      port      = regex("expose:[^:]+:(\\d+)", lxc.tags)[0]
      local_url = "http://${trimprefix(lxc.network[0].ip, "/24")}:${regex("expose:[^:]+:(\\d+)", lxc.tags)[0]}"
    }
    if can(regex("expose:", lxc.tags))
  }
}
```

**メリット:** LXC を作るだけで自動公開  
**デメリット:** 複雑、デバッグしづらい

---

## 🔧 使い方（実例）

### 例1: Home Assistant を公開

```hcl
# terraform.tfvars
services = {
  "homeassistant" = {
    subdomain   = "home"
    local_url   = "http://192.168.0.102:8123"
    description = "Home Assistant"
  }
}
```

```powershell
terraform apply
```

→ `https://home.youkan.uk` で Home Assistant にアクセス可能

### 例2: 複数サービスを同時公開

```hcl
services = {
  "nextcloud" = {
    subdomain   = "cloud"
    local_url   = "http://192.168.0.101:80"
    description = "Nextcloud"
  }
  "homeassistant" = {
    subdomain   = "home"
    local_url   = "http://192.168.0.102:8123"
    description = "Home Assistant"
  }
  "grafana" = {
    subdomain   = "metrics"
    local_url   = "http://192.168.0.103:3000"
    description = "Grafana Monitoring"
  }
}
```

---

## ⚙️ 設定済みファイル

作成したファイル一覧：

1. **`proxmox/services.tf`** - 自動サービス検出の基本構造
2. **`proxmox/auto_expose.tf`** - タグベース自動公開の実装パターン
3. **`proxmox/example_services.tf`** - Nextcloud/Home Assistant の実装例
4. **`services_integration.tf`** - 手動 + 自動サービスの統合

現在は **コメントアウト/count=0** で無効化されています。

---

## 📝 使用開始手順

### オプションA: 手動設定で開始（推奨）

1. `terraform.tfvars` に `services` を追加
2. `terraform apply`

### オプションB: 半自動化を有効化

1. `variables.tf` に以下を追加:

```hcl
variable "enable_nextcloud" {
  type    = bool
  default = false
}

variable "enable_homeassistant" {
  type    = bool
  default = false
}
```

2. `proxmox/example_services.tf` の `count = 0` を以下に変更:

```hcl
count = var.enable_nextcloud ? 1 : 0
```

3. `terraform.tfvars` で有効化:

```hcl
enable_nextcloud     = true
enable_homeassistant = false
```

4. `terraform apply`

---

## 🛠️ トラブルシューティング

### エラー: "connection refused"

原因: cloudflared が `local_url` にアクセスできない

解決策:
1. cloudflared を実行している環境から `curl http://192.168.0.101:80` でアクセス確認
2. LXC のファイアウォール設定を確認
3. ネットワークセグメントが同じか確認

### エラー: "cannot parse IP address"

原因: Proxmox の network IP が CIDR 形式 (`192.168.0.101/24`) になっている

解決策:
```hcl
local_url = "http://${split("/", proxmox_lxc.nextcloud[0].network[0].ip)[0]}:80"
```

### サービスが 404 になる

原因: Tunnel 設定が反映されていない

解決策:
1. cloudflared を再起動
2. `terraform output tunnel_token` で最新トークンを確認
3. Cloudflare ダッシュボードで Tunnel 設定を確認

---

## 🎓 次のステップ

1. **Proxmox テンプレート作成**
   - Cloud-init テンプレートで LXC を高速デプロイ
   - Ansible でサービスを自動インストール

2. **動的 IP 管理**
   - DHCP + 動的 DNS 更新
   - Terraform data source で既存 LXC を検出

3. **Cloudflare Access 統合**
   - サービスごとに認証を追加
   - SSO (Google/GitHub) との連携

4. **監視とアラート**
   - Cloudflare Analytics
   - Uptime monitoring
   - Prometheus + Grafana

---

## 📞 参考リンク

- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Terraform Dynamic Blocks](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks)
