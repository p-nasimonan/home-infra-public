# 🚀 新しいサービスの追加方法

このガイドでは、新しいサービス（例: Nextcloud）をゼロから追加する手順を説明します。

## 📋 前提条件

- Proxmoxクラスタが稼働中
- Terraform/Cloudflareの設定が完了
- Ubuntu 22.04 LXCテンプレートがダウンロード済み

## 🎯 2つの追加方法

### 方法A: Terraformで新規LXC作成 + 公開

完全にIaCで管理したい場合

### 方法B: 既存のLXC/VMを公開のみ

手動で作成済みのサービスを公開したい場合

---

## 方法A: Terraformで新規LXC作成 + 公開

### ステップ1: vms.tf にリソース追加

`vms.tf` を開き、コメントアウトされているテンプレートをコピーして編集：

```hcl
# Nextcloud LXC
resource "proxmox_virtual_environment_container" "nextcloud" {
  description  = "Nextcloud file sharing service"
  node_name    = "anko"  # または "aduki", "monaka"
  unprivileged = true
  
  initialization {
    hostname = "nextcloud"
    
    user_account {
      password = "MySecurePassword123!"  # 変更必須
    }
    
    ip_config {
      ipv4 {
        address = "192.168.0.101/24"  # 未使用のIPを指定
        gateway = "192.168.0.1"
      }
    }
  }
  
  operating_system {
    template_file_id = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
    type             = "ubuntu"
  }
  
  cpu {
    cores = 2  # 必要に応じて調整
  }
  
  memory {
    dedicated = 2048  # MB単位
  }
  
  disk {
    datastore_id = "local-lvm"
    size         = 16  # GB単位
  }
  
  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }
  
  started       = true
  start_on_boot = true
  
  tags = ["nextcloud", "web", "managed"]
}
```

### ステップ2: Terraform でLXC作成

```powershell
# プラン確認
terraform plan -target=proxmox_virtual_environment_container.nextcloud

# LXC作成（他のリソースには影響しない）
terraform apply -target=proxmox_virtual_environment_container.nextcloud
```

### ステップ3: LXCにサービスをインストール

```bash
# SSH接続
ssh root@192.168.0.101
# パスワード: 上記で設定したもの

# システム更新
apt update && apt upgrade -y

# Nextcloudインストール（例）
apt install -y apache2 mariadb-server php php-mysql
wget https://download.nextcloud.com/server/releases/latest.tar.bz2
tar -xjf latest.tar.bz2 -C /var/www/
chown -R www-data:www-data /var/www/nextcloud

# ブラウザで http://192.168.0.101 にアクセスして初期設定
```

### ステップ4: terraform.tfvars にサービス追加

`terraform.tfvars` を編集：

```hcl
services = {
  proxmox = {
    subdomain   = "pve"
    local_url   = "https://192.168.0.13:8006"
    description = "Proxmox VE Console"
  }
  
  # 新規追加
  nextcloud = {
    subdomain   = "cloud"
    local_url   = "http://192.168.0.101:80"
    description = "Nextcloud File Sharing"
  }
}
```

### ステップ5: Cloudflare Tunnel設定を更新

```powershell
# プラン確認
terraform plan

# 適用（Tunnel設定とDNSレコードのみ更新）
terraform apply
```

### ステップ6: 動作確認

ブラウザで https://cloud.youkan.uk にアクセス

---

## 方法B: 既存のLXC/VMを公開のみ

### 前提: 既にLXC/VMが稼働中

- LXC VMID: 200
- IP: 192.168.0.50
- サービス: Home Assistant (ポート 8123)

### ステップ1: terraform.tfvars にサービス追加のみ

```hcl
services = {
  proxmox = {
    subdomain   = "pve"
    local_url   = "https://192.168.0.13:8006"
    description = "Proxmox VE Console"
  }
  
  # 既存サービスを追加
  homeassistant = {
    subdomain   = "home"
    local_url   = "http://192.168.0.50:8123"
    description = "Home Assistant Smart Home"
  }
}
```

### ステップ2: Terraform適用

```powershell
terraform plan
terraform apply
```

### ステップ3: 動作確認

ブラウザで https://home.youkan.uk にアクセス

---

## 📊 IP アドレス管理

### 推奨IP範囲

- **192.168.0.1 - 192.168.0.50**: ルーター、既存デバイス
- **192.168.0.51 - 192.168.0.99**: 手動管理のLXC/VM
- **192.168.0.100 - 192.168.0.199**: Terraform管理のLXC/VM
- **192.168.0.200 - 192.168.0.254**: 予備

### 現在使用中のIP

| IP | ホスト名 | 用途 | 管理 |
|----|---------|------|------|
| 192.168.0.2 | infra-runner | Terraform実行環境 | Terraform (DHCP) |
| 192.168.0.13 | aduki | Proxmoxノード | 手動 |
| 192.168.0.14 | anko | Proxmoxノード | 手動 |
| 192.168.0.15 | monaka | Proxmoxノード | 手動 |

---

## 🎨 サービス例とポート番号

| サービス | デフォルトポート | 推奨IP範囲 |
|---------|---------------|-----------|
| Nextcloud | 80/443 | 192.168.0.101 |
| Home Assistant | 8123 | 192.168.0.102 |
| Jellyfin | 8096 | 192.168.0.103 |
| GitLab | 80/443 | 192.168.0.104 |
| Pi-hole | 80 | 192.168.0.105 |
| Bitwarden | 80/443 | 192.168.0.106 |
| Grafana | 3000 | 192.168.0.107 |
| Portainer | 9000 | 192.168.0.108 |

---

## 🔧 トラブルシューティング

### LXCが作成されない

```powershell
# エラーメッセージを確認
terraform apply -target=proxmox_virtual_environment_container.nextcloud

# よくあるエラー:
# - IPアドレスが重複 → 別のIPに変更
# - テンプレートがない → Proxmoxでダウンロード
# - ストレージ不足 → disk sizeを小さくする
```

### サービスに接続できない

```bash
# LXC内で確認
ssh root@192.168.0.101

# サービスが起動しているか確認
systemctl status apache2  # Nextcloudの場合
systemctl status homeassistant  # Home Assistantの場合

# ポートが開いているか確認
netstat -tlnp | grep :80
```

### Cloudflare Tunnel経由でアクセスできない

```bash
# infra-runner LXCでCloudflaredの状態確認
ssh root@192.168.0.2
systemctl status cloudflared

# ログ確認
journalctl -u cloudflared -f

# Tunnel設定確認
cloudflared tunnel info
```

---

## 🗑️ サービスの削除

### 公開を停止（LXCは残す）

```hcl
# terraform.tfvars から該当サービスを削除
services = {
  proxmox = { ... }
  # nextcloud行を削除
}
```

```powershell
terraform apply
```

### LXCも削除

```powershell
# vms.tfから該当リソースを削除またはコメントアウト

# 削除実行
terraform destroy -target=proxmox_virtual_environment_container.nextcloud
```

---

## 📝 まとめ

### 2つのフローの使い分け

**方法A (Terraform管理):**
- ✅ IaCで完全管理
- ✅ 再現性が高い
- ✅ バージョン管理
- ❌ 初期設定が複雑

**方法B (既存サービス公開):**
- ✅ 既存環境を活かせる
- ✅ すぐに公開可能
- ✅ Proxmox UIで直感的に管理
- ❌ Terraformで管理されない

### 推奨フロー

1. **検証段階**: 方法Bで手動作成・テスト
2. **本番環境**: 方法Aでコード化

これにより、安全かつ効率的にサービスを追加できます！
