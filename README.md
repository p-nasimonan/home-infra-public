# Home Infrastructure as Code

Terraformを使用して自宅インフラ(Cloudflare Tunnel + Proxmox VE)を管理するリポジトリです。

色々試したけど、確かに魔法のように自動でコンテナやcloudflareの設定もしてくれた。でも
あんまりコードで管理するメリットがなくて再現性が高いのはいいことだけど..うーん一つのサービスを建てるのに使うなら楽だけど初期設定面倒。もっといい方法ないかな

## 🚀 概要

このプロジェクトでは以下を管理します:

- **Cloudflare Tunnel**: ローカルサービスを安全に公開
- **Cloudflare DNS**: youkan.ukドメインのDNSレコード管理
- **Proxmox VE**: VM/LXCコンテナ、ネットワーク設定の管理
- **隔離ネットワーク**: 10.0.0.0/24 ゾーン (192.168.1.0/24からのみアクセス可能)

### 3. Terraformの初期化

```powershell
terraform init
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

## GitHub Actions での自動実行

#### 1. Self-hosted runner のセットアップ

詳細は [GITHUB_RUNNER_SETUP.md](GITHUB_RUNNER_SETUP.md) を参照


#### 2. GitHub Secrets の設定

リポジトリ Settings → Secrets and variables → Actions で設定:
- `CLOUDFLARE_API_TOKEN` - Cloudflare API トークン
- `PROXMOX_TOKEN_ID` - Proxmox API Token ID（例: terraform@pve!terraform）
- `PROXMOX_TOKEN_SECRET` - Proxmox API Token Secret

> **注意**: Account ID, Zone ID, API URL はデフォルト値があるため設定不要です。


GitHub Actions タブで実行状況を確認:  
https://github.com/p-nasimonan/home-infra/actions

## 🔗 参考リンク

- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
