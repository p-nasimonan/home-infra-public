

### 1. サービスを公開する

`terraform.tfvars`ファイルを編集して、公開したいサービスを追加:

```hcl
services = {
  "homeassistant" = {
    subdomain   = "home"
    local_url   = "http://192.168.0.100:8123"
    description = "Home Assistant"
  }
  "nextcloud" = {
    subdomain   = "cloud"
    local_url   = "http://192.168.0.101:80"
    description = "Nextcloud"
  }
}
```

### 2. プランを確認

```powershell
terraform plan
```

これで以下が作成されます:
- Cloudflare Tunnel (home-tunnel)
- 各サービスのCNAMEレコード (例: home.youkan.uk)
- Tunnel設定

### 3. 適用

```powershell
terraform apply
```

確認プロンプトで `yes` と入力。

### 4. Tunnel Tokenを取得

```powershell
terraform output -raw tunnel_token
```

このトークンをコピーしてください。

### 5. ローカルPCでCloudflaredを起動

**方法1: Tunnel Tokenを使用 (推奨)**
```powershell
cloudflared tunnel run --token <上記でコピーしたtoken>
```

**方法2: Tunnel IDを使用**
```powershell
# Tunnel IDを確認
terraform output tunnel_id

# Cloudflaredを起動
cloudflared tunnel --no-autoupdate run <tunnel_id>
```

### 6. 動作確認

ブラウザで `https://home.youkan.uk` などにアクセスして確認。

## 📚 よくある作業

### サービスを追加

1. `terraform.tfvars`の`services`に追加
2. `terraform plan`で確認
3. `terraform apply`で適用
4. Cloudflaredを再起動(自動的に新しい設定を読み込みます)

### Proxmox VE/LXCを作成

1. `proxmox/vms.tf`のコメントを解除・編集
2. `terraform plan`で確認
3. `terraform apply`で適用

### ネットワーク設定を追加

1. `proxmox/network.tf`を編集
2. または、Proxmox Web UIで手動設定も可能

## 🔧 トラブルシューティング

### Cloudflared接続エラー

```powershell
# ログを詳細表示
cloudflared tunnel --loglevel debug run <tunnel_id>
```

### Terraform エラー

```powershell
# 設定検証
terraform validate

# 状態確認
terraform show

# プロバイダーキャッシュをクリア
Remove-Item -Recurse -Force .terraform
terraform init
```

### Proxmox API エラー

```powershell
# API接続テスト
curl -k "https://192.168.0.13:8006/api2/json/version" `
  -H "Authorization: PVEAPIToken=terraform@pve!terraform=proxmoxapi"
```

## ⚠️ 重要な注意事項

### ローカルPC vs Proxmox LXC

現在の設定では**ローカルPCでterraformを実行**する想定です。

**ローカルPCで実行する場合:**
- ✅ すぐに開始できる
- ✅ Zone設定などが即座に反映される
- ❌ PCを起動していないと管理できない

**Proxmox LXCで実行する場合:**
1. LXCコンテナを作成 (手動またはTerraformで)
2. コンテナにTerraformとGitをインストール
3. このリポジトリをクローン
4. `.env`または`terraform.tfvars`を設定
5. `terraform init && terraform plan`

## 🎓 次に学ぶべきこと

1. **Terraformの基本**
   - `terraform plan` / `apply` / `destroy`
   - State管理
   - モジュール化

2. **Cloudflare Tunnel**
   - アクセス制御 (Cloudflare Access)
   - WAF設定
   - Rate Limiting

3. **Proxmox自動化**
   - Cloud-initテンプレート作成
   - LXCコンテナの自動プロビジョニング
   - Ansibleとの連携

4. **セキュリティ強化**
   - Terraform State暗号化
   - Secrets管理 (Vault, SOPS)
   - APIトークンのローテーション

## 📞 サポート

- [Terraform Cloudflare Provider Docs](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Terraform Proxmox Provider Docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
