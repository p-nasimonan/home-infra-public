# Home Infrastructure as Code

Terraformを使用して自宅インフラ(Cloudflare Tunnel + Proxmox VE)を管理するリポジトリです。

## 🚀 概要

このプロジェクトでは以下を管理します:

- **Cloudflare Tunnel**: ローカルサービスを安全に公開
- **Cloudflare DNS**: youkan.ukドメインのDNSレコード管理
- **Proxmox VE**: VM/LXCコンテナ、ネットワーク設定の管理
- **隔離ネットワーク**: 10.0.0.0/24 ゾーン (192.168.1.0/24からのみアクセス可能)

## 📋 前提条件

- Terraform >= 1.0
- Cloudflared CLI
- Cloudflare APIトークン (Zone:DNS:Edit, Account:Cloudflare Tunnel:Edit)
- Proxmox VE API Token
- Git

## 🛠️ セットアップ

### 1. ツールのインストール

```powershell
# Terraform
winget install --id Hashicorp.Terrafor
m

# Cloudflared
winget install --id Cloudflare.cloudflared
```

### 2. 環境変数の設定

`.env.example`をコピーして`.env`を作成し、必要な値を設定:


### 3. Terraformの初期化

```powershell
terraform init
```

## 📁 プロジェクト構造

```
home-infra/
├── .github/
│   └── workflows/
│       └── deploy_to_runner.yml  # GitHub Actions (self-hosted runner)
├── .gitignore
├── README.md
├── ISOLATED_NETWORK.md          # 隔離ネットワーク設定ガイド
├── QUICKSTART.md                # クイックスタートガイド
├── ARCHITECTURE.md              # アーキテクチャとフロー説明
├── FLOW_DIAGRAM.md              # フロー図解
├── ADD_SERVICE.md               # 新サービス追加手順
├── GITHUB_RUNNER_SETUP.md       # Self-hosted runner セットアップ
├── providers.tf                 # Terraformプロバイダー設定
├── variables.tf                 # 変数定義
├── terraform.tfvars             # 変数値(Git管理外)
├── terraform.tfvars.example     # 変数値のテンプレート
├── outputs.tf                   # 出力値
├── tunnel.tf                    # Cloudflare Tunnel設定
├── dns.tf                       # DNS設定
├── vms.tf                       # Proxmox VM/LXC設定
├── network.tf                   # Proxmoxネットワーク設定
├── firewall.tf                  # Proxmoxファイアウォール設定
├── setup_runner.sh              # infra-runner セットアップスクリプト
├── setup_github_runner.sh       # GitHub Actions runner セットアップ
├── setup_nat_gateway.sh         # NAT Gateway セットアップスクリプト
└── ansible/
    ├── playbook-nat-gateway.yml # NAT設定Ansible Playbook
    └── inventory-nat-gateway.ini # NAT Gateway インベントリ
```

## 🔑 認証情報

### Cloudflare API Token

以下の権限が必要:
- `Zone:DNS:Edit` - DNSレコードの編集
- `Account:Cloudflare Tunnel:Edit` - Tunnelの管理
- `Zone:Zone:Read` - Zone情報の読み取り

### Proxmox API Token

以下の権限が必要:
- VM/LXC の作成・編集・削除
- ネットワーク設定の編集

## 📝 使用方法

### ローカルでの実行

#### プランの確認

```powershell
terraform plan
```

#### 適用

```powershell
terraform apply
```

#### 削除

```powershell
terraform destroy
```

### GitHub Actions での自動実行（推奨）

#### 1. Self-hosted runner のセットアップ

詳細は [GITHUB_RUNNER_SETUP.md](GITHUB_RUNNER_SETUP.md) を参照

```bash
# infra-runner LXC で実行
ssh root@192.168.0.2
cd /root/infrastructure/home-infra
bash setup_github_runner.sh <GITHUB_RUNNER_TOKEN>
```

#### 2. GitHub Secrets の設定

リポジトリ Settings → Secrets and variables → Actions で設定:
- `CLOUDFLARE_API_TOKEN` - Cloudflare API トークン
- `PROXMOX_TOKEN_ID` - Proxmox API Token ID（例: terraform@pve!terraform）
- `PROXMOX_TOKEN_SECRET` - Proxmox API Token Secret

> **注意**: Account ID, Zone ID, API URL はデフォルト値があるため設定不要です。

#### 3. 自動デプロイ

```bash
# main ブランチに push すると自動実行
git add .
git commit -m "Update infrastructure"
git push origin main
```

GitHub Actions タブで実行状況を確認:  
https://github.com/p-nasimonan/home-infra/actions

## 🔗 参考リンク

- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
