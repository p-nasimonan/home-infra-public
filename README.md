# Home Infrastructure as Code

Terraformを使用して自宅インフラ(Cloudflare Tunnel + Proxmox VE)を管理するリポジトリです。

## 🚀 概要

このプロジェクトでは以下を管理します:

- **Cloudflare Tunnel**: ローカルサービスを安全に公開
- **Cloudflare DNS**: youkan.ukドメインのDNSレコード管理
- **Proxmox VE**: VM/LXCコンテナ、ネットワーク設定の管理

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
winget install --id Hashicorp.Terraform

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
├── .env                    # 環境変数(Git管理外)
├── .env.example            # 環境変数のテンプレート
├── .gitignore
├── README.md
├── providers.tf            # Terraformプロバイダー設定
├── variables.tf            # 変数定義
├── terraform.tfvars        # 変数値(Git管理外)
├── cloudflare/            # Cloudflare関連
│   ├── tunnel.tf          # Cloudflare Tunnel設定
│   ├── dns.tf             # DNS設定
│   └── outputs.tf         # 出力値
└── proxmox/               # Proxmox関連
    ├── network.tf         # ネットワーク設定
    ├── vms.tf             # VM/LXC設定
    └── outputs.tf         # 出力値
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

### プランの確認

```powershell
terraform plan
```

### 適用

```powershell
terraform apply
```

### 削除

```powershell
terraform destroy
```

## 🔗 参考リンク

- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
