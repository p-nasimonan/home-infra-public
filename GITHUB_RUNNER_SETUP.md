# 🤖 GitHub Actions Self-Hosted Runner セットアップガイド

## 概要

infra-runner LXC に GitHub Actions の self-hosted runner をインストールして、リポジトリへの push で自動的に Terraform を実行できるようにします。

## なぜ self-hosted runner？

### SSH + rsync 方式と比較したメリット

| 項目 | SSH + rsync | Self-Hosted Runner |
|------|-------------|-------------------|
| **セキュリティ** | SSH 秘密鍵を GitHub に保存 | runner token のみ（一時的） |
| **シンプルさ** | rsync, SSH コマンド必要 | GitHub がネイティブ対応 |
| **ログ/監査** | 限定的 | GitHub UI で完全な履歴 |
| **並列実行** | 手動管理が必要 | GitHub が自動管理 |
| **secrets 管理** | terraform.tfvars に直書き | 環境変数で注入 |

### デメリット

- infra-runner が常時稼働している必要がある
- GitHub との通信が必要（インターネット接続）
- runner の管理（更新、監視）が必要

## 📋 セットアップ手順

### ステップ1: GitHub で runner token を取得

1. リポジトリにアクセス:  
   https://github.com/p-nasimonan/home-infra

2. **Settings** → **Actions** → **Runners** に移動

3. **New self-hosted runner** をクリック

4. **Linux** を選択

5. 表示される **registration token** をコピー（後で使用）

   ```
   例: ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
   ```

### ステップ2: infra-runner にセットアップスクリプトをコピー

```bash
# infra-runner に SSH 接続
ssh root@192.168.0.2
# パスワード: Terraform2024!

# リポジトリをクローン（まだの場合）
cd /root/infrastructure
git clone https://github.com/p-nasimonan/home-infra.git
cd home-infra

# または、既にクローン済みなら最新版を取得
cd /root/infrastructure/home-infra
git pull
```

### ステップ3: runner をセットアップ

```bash
# セットアップスクリプトを実行（ステップ1で取得した TOKEN を指定）
bash setup_github_runner.sh <GITHUB_RUNNER_TOKEN>

# 例:
# bash setup_github_runner.sh ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
```

スクリプトは以下を自動実行します：
1. 必要なパッケージインストール
2. `runner` ユーザー作成
3. GitHub Actions runner ダウンロード
4. runner 設定（自動・無人モード）
5. systemd サービス登録
6. サービス起動

### ステップ4: runner が登録されたか確認

**GitHub UI で確認:**  
https://github.com/p-nasimonan/home-infra/settings/actions/runners

`infra-runner` が **Idle** または **Active** 状態になっていれば成功です。

**LXC 内で確認:**
```bash
cd /home/runner/actions-runner
sudo ./svc.sh status

# 期待される出力:
# ● actions.runner.p-nasimonan-home-infra.infra-runner.service
#    Active: active (running)
```

### ステップ5: GitHub Secrets を設定

リポジトリの **Settings** → **Secrets and variables** → **Actions** で以下を追加：

| Secret 名 | 値 | 説明 |
|-----------|---|------|
| `CLOUDFLARE_API_TOKEN` | `your_cloudflare_token` | Cloudflare API トークン（必須） |
| `PROXMOX_TOKEN_ID` | `terraform@pve!terraform` | Proxmox API Token ID（必須） |
| `PROXMOX_TOKEN_SECRET` | `881342d5-23c3...` | Proxmox API Token Secret（必須） |

> **注意**: `cloudflare_account_id`, `cloudflare_zone_id`, `proxmox_api_url` はデフォルト値があるため、Secrets の設定は不要です。`variables.tf` にハードコードされています。

### ステップ6: ワークフローをテスト

```bash
# ローカルで何か変更してコミット
git add .
git commit -m "test: GitHub Actions with self-hosted runner"
git push origin main
```

GitHub の **Actions** タブで実行状況を確認：  
https://github.com/p-nasimonan/home-infra/actions

成功すれば、以下が自動実行されます：
1. リポジトリを checkout
2. `terraform.tfvars` を GitHub Secrets から生成
3. `terraform init`
4. `terraform validate`
5. `terraform plan`
6. `terraform apply`（main ブランチへの push の場合）

## 🔧 運用・管理

### runner の状態確認

```bash
ssh root@192.168.0.2
cd /home/runner/actions-runner
sudo ./svc.sh status
```

### runner の再起動

```bash
cd /home/runner/actions-runner
sudo ./svc.sh restart
```

### runner のログ確認

```bash
journalctl -u actions.runner.p-nasimonan-home-infra.infra-runner.service -f
```

### runner の更新

```bash
# 新しいバージョンがリリースされた場合
cd /home/runner/actions-runner
sudo ./svc.sh stop
sudo -u runner ./config.sh remove --token <NEW_TOKEN>

# setup_github_runner.sh のバージョン番号を更新して再実行
# または手動で最新版をダウンロード
```

### runner の削除

```bash
cd /home/runner/actions-runner
sudo ./svc.sh stop
sudo ./svc.sh uninstall
sudo -u runner ./config.sh remove --token <NEW_TOKEN>
```

## 🔒 セキュリティ考慮事項

### ✅ 推奨設定

1. **runner ユーザーの権限制限**
   - 専用ユーザー（`runner`）で実行
   - root 権限は不要（Terraform は root 以外で実行可能）

2. **ネットワーク制限**
   ```bash
   # Proxmox API へのアクセスのみ許可（例）
   iptables -A OUTPUT -d 192.168.0.13 -j ACCEPT
   iptables -A OUTPUT -d api.cloudflare.com -j ACCEPT
   iptables -A OUTPUT -j DROP
   ```

3. **Terraform state の保護**
   - リモートバックエンド使用を推奨（Terraform Cloud, S3 + DynamoDB）
   - ローカル state ファイルは暗号化

4. **secrets の保護**
   - `terraform.tfvars` は実行後に削除（ワークフロー内で実施済み）
   - GitHub Secrets を使用（平文保存しない）

### ⚠️ 注意事項

1. **Public リポジトリでは使用しない**
   - self-hosted runner は public リポジトリでは危険
   - 現在のリポジトリが private であることを確認

2. **runner の定期更新**
   - GitHub Actions runner は定期的に更新される
   - セキュリティパッチ適用のため、最新版を維持

3. **ログの監視**
   - runner のログを定期的に確認
   - 不審な実行がないかチェック

## 📊 ワークフローのカスタマイズ

### 手動実行（plan のみ）

GitHub の **Actions** タブ → **Deploy Terraform on infra-runner** → **Run workflow**

- **Terraform action**: `plan` を選択
- → 変更内容を確認のみ（apply はしない）

### 手動実行（apply）

- **Terraform action**: `apply` を選択
- → 強制的に apply を実行

### 手動実行（destroy）

- **Terraform action**: `destroy` を選択
- → ⚠️ 全リソースを削除（注意！）

### 自動実行の制御

`.github/workflows/deploy_to_runner.yml` の `paths` を編集：

```yaml
on:
  push:
    branches: [ main ]
    paths:
      - '**.tf'                    # .tf ファイル変更時のみ
      - 'terraform.tfvars.example' # サンプル変更時
      - '.github/workflows/**'     # ワークフロー変更時
```

## 🚀 高度な設定

### 複数の runner を追加

```bash
# 別のノード（aduki）にも runner を追加
ssh root@aduki
bash setup_github_runner.sh <TOKEN_2>

# 異なるラベルを付けることで使い分け可能
# 例: terraform, cloudflared, backup など
```

### Pull Request でのプレビュー

ワークフローに追加：

```yaml
on:
  pull_request:
    branches: [ main ]

jobs:
  terraform-pr-plan:
    runs-on: [self-hosted, Linux, terraform]
    steps:
      # ... terraform plan のみ実行
      # 結果を PR コメントに投稿
```

### Slack/Discord 通知

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1.24.0
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "Terraform apply completed: ${{ job.status }}"
      }
```

## 📝 トラブルシューティング

### runner が Offline になる

```bash
# サービスを再起動
cd /home/runner/actions-runner
sudo ./svc.sh restart

# ログを確認
journalctl -u actions.runner.* -f
```

### Terraform が失敗する

```bash
# infra-runner で手動実行してエラーを確認
ssh root@192.168.0.2
cd /root/infrastructure/home-infra
terraform init
terraform plan
```

### GitHub Secrets が反映されない

- リポジトリ Settings で Secrets が正しく設定されているか確認
- ワークフローファイルで `${{ secrets.XXX }}` の名前が一致しているか確認

## 🎓 まとめ

self-hosted runner を使うことで：

✅ **セキュリティ向上**: SSH 鍵不要、secrets は環境変数  
✅ **運用効率化**: GitHub UI で完全管理、履歴が残る  
✅ **自動化**: push するだけで自動デプロイ  
✅ **柔軟性**: 手動実行、PR プレビュー、通知など拡張可能  

これで、GitHub に push するだけで自動的に Terraform が実行され、インフラが更新されます！
