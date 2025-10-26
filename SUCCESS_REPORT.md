# 🎉 LXC作成成功レポート

## 概要
Telmate/proxmoxプロバイダーからbpg/proxmoxプロバイダーへの移行により、Proxmox VE 9.0.11でのLXC作成に成功しました。

## 問題の原因
- **Telmate/proxmox v2.9.14**: Proxmox VE 9.0に存在しない`VM.Monitor`権限を要求
- Proxmox VE 9.0では権限システムが変更されており、旧プロバイダーは非互換

## 解決策
1. **プロバイダー変更**: `Telmate/proxmox` → `bpg/proxmox v0.85.1`
2. **リソース構文更新**: `proxmox_lxc` → `proxmox_virtual_environment_container`
3. **非特権コンテナ設定**: `unprivileged = true`で作成

## 作成されたLXC情報

### 基本情報
- **ホスト名**: infra-runner
- **VMID**: 105
- **ノード**: anko
- **IPアドレス**: 192.168.0.2
- **ステータス**: ✅ 稼働中

### スペック
- **CPU**: 2コア
- **メモリ**: 4GB (4294967296 bytes)
- **ディスク**: 16GB (16729894912 bytes)
- **OS**: Ubuntu 22.04 (unprivileged container)
- **ネットワーク**: eth0 (vmbr0), DHCP

### 機能
- **Nesting**: 有効 (Dockerコンテナ実行可能)
- **自動起動**: 有効
- **タグ**: terraform, cloudflared, infra, managed

## 次のステップ

### 1. LXCへのアクセス
```bash
# Proxmoxホストから
pct enter 105

# または SSH経由
ssh root@192.168.0.2
# パスワード: Terraform2024!
```

### 2. 必要なソフトウェアのインストール

LXC内で以下を実行：

```bash
# システム更新
apt-get update && apt-get upgrade -y

# 基本パッケージ
apt-get install -y curl wget git gnupg software-properties-common ca-certificates unzip

# Terraform インストール
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y terraform

# Cloudflared インストール
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared-linux-amd64.deb
rm cloudflared-linux-amd64.deb
```

### 3. Gitリポジトリのクローン

```bash
mkdir -p /root/infrastructure
cd /root/infrastructure
git clone https://github.com/p-nasimonan/home-infra.git
cd home-infra
```

### 4. Cloudflared Tunnelの起動

Tunnel Tokenを取得：
```powershell
terraform output -raw tunnel_token
```

LXC内でCloudflaredを起動：
```bash
# 手動起動（テスト用）
cloudflared tunnel run --token <TUNNEL_TOKEN>

# systemdサービスとして登録（本番用）
cloudflared service install <TUNNEL_TOKEN>
systemctl start cloudflared
systemctl enable cloudflared
systemctl status cloudflared
```

### 5. 動作確認

Cloudflared起動後、以下にアクセス：
- **Proxmox Console**: https://pve.youkan.uk

## Terraform管理

### 状態確認
```powershell
terraform state list
terraform state show proxmox_virtual_environment_container.terraform_runner
```

### 削除（必要な場合）
```powershell
terraform destroy -target=proxmox_virtual_environment_container.terraform_runner
```

## トラブルシューティング

### LXCが起動しない場合
```bash
# Proxmoxホストで
pct start 105
pct status 105
journalctl -u pve-container@105
```

### ネットワークに接続できない場合
```bash
# LXC内で
ip addr show
ping 8.8.8.8
cat /etc/resolv.conf
```

### Cloudflaredが起動しない場合
```bash
# LXC内で
cloudflared tunnel info
systemctl status cloudflared
journalctl -u cloudflared -f
```

## まとめ

✅ **成功した点**:
- bpg/proxmoxプロバイダーがProxmox VE 9.0に完全対応
- LXC作成が自動化され、IaC (Infrastructure as Code)として管理可能
- 権限問題を解決し、API Token経由での操作が可能

📝 **学んだこと**:
- Proxmox VE 9.0は権限システムが変更されている
- 公式プロバイダーより、コミュニティプロバイダー(bpg/proxmox)の方が最新バージョンに対応
- unprivileged containerの使用でセキュリティ向上

🚀 **今後の展開**:
- このLXC内からTerraformを実行することで、完全自動化が可能
- Cloudflared Tunnelでインターネットからのアクセスが可能
- 他のサービス(Nextcloud, Home Assistantなど)も同様に展開可能
