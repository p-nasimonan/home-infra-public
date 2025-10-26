# インフラストラクチャ アーキテクチャ

## 📁 ファイル構造と役割

```
home-infra/
├── providers.tf          # Terraform/Cloudflare/Proxmoxプロバイダー設定
├── variables.tf          # 変数定義
├── terraform.tfvars      # 変数の実際の値（Gitignore推奨）
├── terraform.tfvars.example  # 変数のサンプル
│
├── vms.tf               # VM/LXCコンテナ定義（Proxmoxリソース）
├── tunnel.tf            # Cloudflare Tunnel設定
├── dns.tf               # DNS CNAMEレコード設定
├── network.tf           # ネットワーク関連設定（未使用）
├── outputs.tf           # 出力値（Tunnel Token, URLなど）
│
└── *.md                 # ドキュメント
```

## 🔄 リソース作成フロー

### フロー1: VM/LXCコンテナの作成

```
1. vms.tf でリソース定義
   ↓
2. terraform apply
   ↓
3. Proxmoxにコンテナ作成
   ↓
4. 手動でサービスをインストール/設定
   (例: Nextcloud, Home Assistant)
```

**ファイル**: `vms.tf`

```hcl
# 例: Nextcloud LXC
resource "proxmox_virtual_environment_container" "nextcloud" {
  description = "Nextcloud file sharing service"
  node_name   = "anko"
  unprivileged = true
  
  initialization {
    hostname = "nextcloud"
    user_account {
      password = "changeme"
    }
    ip_config {
      ipv4 {
        address = "192.168.0.101/24"
        gateway = "192.168.0.1"
      }
    }
  }
  
  operating_system {
    template_file_id = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
    type            = "ubuntu"
  }
  
  cpu { cores = 2 }
  memory { dedicated = 2048 }
  disk {
    datastore_id = "local-lvm"
    size         = 16
  }
  
  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }
  
  started       = true
  start_on_boot = true
  tags          = ["nextcloud", "web", "managed"]
}
```

### フロー2: サービスの公開（Cloudflare Tunnel経由）

```
1. terraform.tfvars の services{} にサービス追加
   ↓
2. terraform apply
   ↓
3. Cloudflare Tunnel設定が更新される
   ↓
4. DNS CNAMEレコードが作成される
   ↓
5. https://subdomain.youkan.uk でアクセス可能
```

**ファイル**: `terraform.tfvars`

```hcl
services = {
  proxmox = {
    subdomain   = "pve"
    local_url   = "https://192.168.0.13:8006"
    description = "Proxmox VE Console"
  }
  nextcloud = {
    subdomain   = "cloud"
    local_url   = "http://192.168.0.101:80"
    description = "Nextcloud File Sharing"
  }
}
```

**処理される場所**:
- `tunnel.tf` - Tunnel設定にサービスを追加
- `dns.tf` - 各サービスのCNAMEレコードを作成

## 🎯 2つのフローの分離理由

### なぜ分けているのか？

1. **独立性**: VM/LXCの作成とサービス公開は独立した操作
   - VMは一度作成したら頻繁に変更しない
   - サービス公開設定は追加・変更が頻繁

2. **柔軟性**: 既存のサービスも公開可能
   - Proxmox外で動いているサービスも公開できる
   - 手動で作ったLXCも`services`に追加するだけ

3. **安全性**: VM削除のリスク回避
   - サービス設定変更でVMが再作成されない
   - `terraform apply`が安全

## 📋 実際の使用例

### ケース1: 新しいサービスをゼロから構築

```bash
# 1. vms.tf にLXC定義を追加
# 2. terraform apply でLXC作成
terraform apply -target=proxmox_virtual_environment_container.nextcloud

# 3. LXCにSSHして、Nextcloudをインストール
ssh root@192.168.0.101
apt install nextcloud

# 4. terraform.tfvars にサービス追加
# services = { nextcloud = { ... } }

# 5. terraform apply でTunnel設定更新
terraform apply
```

### ケース2: 既存のサービスを公開

```bash
# 既にProxmoxで手動作成したLXC (例: 192.168.0.50のHomeAssistant)

# 1. terraform.tfvars にサービス追加のみ
services = {
  homeassistant = {
    subdomain   = "home"
    local_url   = "http://192.168.0.50:8123"
    description = "Home Assistant"
  }
}

# 2. terraform apply
terraform apply

# → https://home.youkan.uk でアクセス可能
```

### ケース3: サービス公開を停止（VMは削除しない）

```bash
# 1. terraform.tfvars から該当サービスを削除
# services = { ... nextcloud行を削除 ... }

# 2. terraform apply
terraform apply

# → Tunnel設定とDNSレコードのみ削除
# → LXCは稼働し続ける（192.168.0.101で直接アクセス可能）
```

## 🔧 vms.tf の管理方針

### 推奨: モジュール的な管理

```hcl
# ==========================================
# Infrastructure LXC (常時稼働)
# ==========================================

resource "proxmox_virtual_environment_container" "terraform_runner" {
  # Terraform/Cloudflared実行環境
  # ...
}

# ==========================================
# Application LXC (サービスごと)
# ==========================================

# Nextcloud
resource "proxmox_virtual_environment_container" "nextcloud" {
  # count = 1  # 0にすると削除
  # ...
}

# Home Assistant
resource "proxmox_virtual_environment_container" "homeassistant" {
  # count = 1
  # ...
}
```

### count を使った制御

```hcl
variable "enable_nextcloud" {
  type    = bool
  default = false
}

resource "proxmox_virtual_environment_container" "nextcloud" {
  count = var.enable_nextcloud ? 1 : 0
  # ...
}
```

## 🎬 推奨ワークフロー

### 新しいサービスを追加する手順

1. **計画**: どんなサービスか決定
   - サービス名、必要なリソース、ポート番号

2. **vms.tf編集**: LXCリソースを追加
   ```bash
   # vms.tfに追加してコミット
   git add vms.tf
   git commit -m "Add Nextcloud LXC definition"
   ```

3. **LXC作成**: Terraform実行
   ```bash
   terraform plan
   terraform apply -target=proxmox_virtual_environment_container.nextcloud
   ```

4. **サービスセットアップ**: LXC内で設定
   ```bash
   ssh root@192.168.0.101
   # Nextcloudインストールスクリプト実行
   ```

5. **公開設定**: terraform.tfvarsにサービス追加
   ```bash
   # terraform.tfvars編集
   vim terraform.tfvars
   ```

6. **Tunnel更新**: Terraform実行
   ```bash
   terraform apply
   ```

7. **動作確認**: ブラウザでアクセス
   ```bash
   https://cloud.youkan.uk
   ```

## 🚫 やってはいけないこと

### ❌ VM定義とサービス公開を同じリソースで管理

```hcl
# 悪い例
resource "proxmox_virtual_environment_container" "nextcloud" {
  # ...
  
  # これをやると、VM変更時にTunnel設定も変わってしまう
  depends_on = [cloudflare_zero_trust_tunnel_cloudflared_config.main]
}
```

### ❌ IPアドレスの動的参照（DHCPの場合）

```hcl
# 悪い例（DHCPでIPが取得できない）
services = {
  nextcloud = {
    local_url = "http://${proxmox_virtual_environment_container.nextcloud.ipv4}:80"
  }
}

# 良い例: 静的IP or Terraform外で管理
services = {
  nextcloud = {
    local_url = "http://192.168.0.101:80"  # 固定IP
  }
}
```

## 📊 現在の状態

### 稼働中のリソース

#### Proxmox LXC
- **infra-runner** (VMID 105)
  - 用途: Terraform/Cloudflared実行環境
  - IP: 192.168.0.2
  - 管理: `vms.tf`

#### Cloudflare Tunnel
- **home-tunnel** (494fcde0-e9e3-435b-8200-84b21823fb93)
  - 公開サービス: Proxmox Console (pve.youkan.uk)
  - 管理: `tunnel.tf`, `dns.tf`, `terraform.tfvars`

### 追加可能なサービス例

- Nextcloud (ファイル共有)
- Home Assistant (スマートホーム)
- Jellyfin (メディアサーバー)
- GitLab/Gitea (Git リポジトリ)
- Pi-hole (DNS広告ブロック)
- Bitwarden (パスワードマネージャー)

## 🔮 今後の拡張

### 自動化の可能性

1. **Ansibleとの連携**: LXC作成後の自動セットアップ
2. **Packer**: カスタムLXCテンプレート作成
3. **Terraform Module**: 再利用可能なサービス定義
4. **CI/CD**: Gitコミットで自動デプロイ

### Module化の例

```hcl
# modules/lxc-service/main.tf
module "nextcloud" {
  source = "./modules/lxc-service"
  
  name        = "nextcloud"
  node_name   = "anko"
  cores       = 2
  memory      = 2048
  disk_size   = 16
  ip_address  = "192.168.0.101"
  
  subdomain   = "cloud"
  port        = 80
  auto_expose = true
}
```
