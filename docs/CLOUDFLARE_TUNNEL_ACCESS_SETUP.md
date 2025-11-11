# Cloudflare Access 手動設定ガイド

## 概要

Cloudflare Access は Terraform v5 では API 制約があるため、以下のアプローチを推奨します：

- ✅ **Tunnel**: Terraform で IaC 管理
- ✅ **DNS**: Terraform で IaC 管理
- 🔧 **Access**: Cloudflare ダッシュボード または API で手動管理

## Cloudflare Tunnel (IaC 管理済み)

以下が Terraform で管理されています：

```hcl
# tunnel.tf
- Tunnel の作成（cloudflare_zero_trust_tunnel_cloudflared）
- Tunnel 設定（cloudflare_zero_trust_tunnel_cloudflared_config）
- DNS CNAME レコード（cloudflare_dns_record）
```

### インストール手順

#### 1. Terraform を適用

```bash
terraform plan
terraform apply
```

#### 2. Tunnel トークンを取得

```bash
terraform output -raw tunnel_token
```

#### 3. infra-runner に cloudflared をインストール

```bash
# infra-runner（LXC）内で実行
sudo apt-get update
sudo apt-get install -y cloudflare-warp

# トークンを設定して起動
cloudflared tunnel run --token <TUNNEL_TOKEN>
```

---

## Cloudflare Access 手動設定

### ステップ 1: アクセスポリシーを作成

1. **Cloudflare ダッシュボード** → **Zero Trust** → **Access** → **Applications**
2. **Create an application** をクリック
3. 以下を設定：
   - **Application type**: Self-hosted
   - **Application name**: Proxmox VE
   - **Application domain**: pve.youkan.uk
   - **Session duration**: 24 hours

### ステップ 2: ポリシーを追加

**Policy 1: メール認証**
- **Policy name**: Allow Admin Emails
- **Criteria**: Email
  - **Email**: your-email@example.com (または GitHub Noreply: username@users.noreply.github.com)
- **Action**: Allow

**Policy 2: IP ホワイトリスト（オプション）**
- **Policy name**: Allow Trusted IPs
- **Criteria**: IP Ranges
  - **IP**: 203.0.113.0/24 (あなたのホームネット)
- **Action**: Allow

**Policy 3: デフォルト（全て拒否）**
- **Policy name**: Default Deny
- **Criteria**: Everyone
- **Action**: Deny

### ステップ 3: ポリシーの優先度を設定

ダッシュボード上でポリシーを以下の順に並べます：

1. Allow Admin Emails
2. Allow Trusted IPs
3. Default Deny

---

## Service Token (CI/CD 用)

将来的に CI/CD パイプラインで Terraform の実行を自動化する場合は、Service Token が必要です。

### 作成方法

Terraform v5 で Service Token を作成すれば、GitHub Actions で使用可能：

```bash
terraform output service_token_id
terraform output -raw service_token_client_id
```

これを GitHub Secrets に設定：

```bash
gh secret set CLOUDFLARE_ACCESS_CLIENT_ID --body "$(terraform output service_token_id)"
gh secret set CLOUDFLARE_ACCESS_SERVICE_TOKEN --body "$(terraform output -raw service_token_client_id)"
```

---

## テスト

### 1. Tunnel がアクティブか確認

```bash
# Proxmox ノードで確認
journalctl -u cloudflared -f
```

### 2. Proxmox にアクセステスト

```bash
curl -i https://pve.youkan.uk
```

→ Cloudflare Access のログイン画面が表示されれば成功

### 3. ブラウザでアクセス

```
https://pve.youkan.uk
```

→ メール認証画面が表示 → ログイン → Proxmox UI に接続

---

## トラブルシューティング

### Tunnel がオフラインの場合

```bash
# infra-runner で確認
ssh root@infra-runner "ps aux | grep cloudflared"

# ログを確認
ssh root@infra-runner "journalctl -u cloudflared -n 50"
```

### DNS が解決されない場合

```bash
# DNS レコードを確認
dig pve.youkan.uk

# Terraform の状態を確認
terraform state show cloudflare_dns_record.tunnel_cnames
```

### Access でログインできない場合

1. メールアドレスが正しいか確認
2. Identity Provider が有効か確認（One-Time PIN など）
3. ポリシーの優先度を確認

---

## 今後の改善

1. **Terraform Access サポート改善**
   - Cloudflare Provider v6 以降でより良いサポートが期待される
   - その時点で `access.tf` を追加

2. **GitHub Actions 統合**
   - Service Token で Terraform の自動実行
   - Ansible での自動デプロイ

3. **モニタリング**
   - Cloudflare ログ分析
   - アクセス監査ログ

---

## 参考資料

- [Cloudflare Zero Trust ドキュメント](https://developers.cloudflare.com/cloudflare-one/)
- [Cloudflare Tunnel Terraform](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/deployment-guides/terraform/)
- [Terraform Cloudflare Provider v5](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/guides/version-5-upgrade)
