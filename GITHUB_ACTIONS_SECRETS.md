# GitHub Actions ワークフロー用 Secrets 設定ガイド

## 必要な Secrets の設定

GitHub リポジトリの Settings → Secrets and variables → Actions から以下を設定：

### 1. `PROXMOX_SSH_KEY` ⭐ （必須）

Proxmox root ユーザーの SSH 秘密鍵

```bash
# ローカルで確認
cat ~/.ssh/id_rsa  # または適切な秘密鍵ファイル
```

GitHub Secrets に登録：
- Name: `PROXMOX_SSH_KEY`
- Value: （秘密鍵の内容をコピペ）

### 2. `TF_VAR_cloudflare_api_token` ⭐ （必須）

Terraform で使用する Cloudflare API トークン

GitHub Secrets に登録：
- Name: `TF_VAR_cloudflare_api_token`
- Value: （Cloudflare API トークン）

### 3. `TF_VAR_proxmox_token_id` ⭐ （必須）

Terraform で使用する Proxmox トークンID

GitHub Secrets に登録：
- Name: `TF_VAR_proxmox_token_id`
- Value: （Proxmox トークンID）

### 4. `TF_VAR_proxmox_token_secret` ⭐ （必須）

Terraform で使用する Proxmox トークンシークレット

GitHub Secrets に登録：
- Name: `TF_VAR_proxmox_token_secret`
- Value: （Proxmox トークンシークレット）

### ~~`PROXMOX_MONAKA_IP`~~ ❌ （不要）

**削除しました！** Terraform state から自動取得されます。

---

## 既存 Secrets との統合

`.github/workflows/deploy_to_runner.yml` と同じ Secrets を使用しています。
既に設定済みなら、追加で設定不要です。

---

## ワークフロー実行

### 方法1: GitHub UI から実行

1. リポジトリの **Actions** タブを開く
2. **Coolify セットアップ自動化** ワークフローを選択
3. **Run workflow** をクリック
4. `action` を選択：
   - `setup`: VM 作成＆Coolify インストール
   - `destroy`: VM 削除
   - `verify`: インストール確認

### 方法2: GitHub CLI から実行

```bash
# Setup を実行
gh workflow run setup-coolify.yml -f action=setup

# Destroy を実行
gh workflow run setup-coolify.yml -f action=destroy

# 実行状況確認
gh run list --workflow=setup-coolify.yml
```

---

## ワークフロー内で使用される環境変数

| 変数 | 用途 | 取得元 |
|------|------|--------|
| `COOLIFY_IP` | Coolify VM の IP | terraform output |
| `MONAKA_IP` | monaka node の hostname | terraform output（data source） |
| `PROXMOX_SSH_KEY` | SSH 秘密鍵 | GitHub Secrets |
| `TF_VAR_*` | Terraform 変数 | GitHub Secrets |

---

## トラブルシューティング

### SSH 接続エラー

```
Permission denied (publickey,password)
```

→ `PROXMOX_SSH_KEY` が正しい秘密鍵か確認
→ Proxmox monaka node に SSH 鍵が登録されているか確認

```bash
# monaka node に SSH キーを登録（一度だけ）
ssh-copy-id -i ~/.ssh/id_rsa.pub root@monaka.youkan.uk
# または IP で
ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.0.14
```

### Terraform State Lock エラー

```
Error: Error acquiring the lock
```

→ 前回の apply が完了していない可能性
→ Terraform Cloud dashboard で state をチェック

### Ansible 接続エラー

```
Failed to connect to the host via ssh
```

→ VM がまだ起動していない可能性
→ ワークフロー内の待機時間を増やす（`sleep` コマンド）

---

## 実行フロー（更新版）

```
GitHub Actions ワークフロー開始
  ↓
Terraform state から monaka node 情報を取得（data source）
  ↓
SSH で monaka にアクセス → クラウドイメージダウンロード
  ↓
Terraform apply → coolify VM 作成（IP: 192.168.0.30）
  ↓
60秒待機
  ↓
SSH テスト × 10回（1回成功したら OK）
  ↓
Ansible inventory 自動生成（IP 埋め込み）
  ↓
Ansible playbook 実行 → Docker + Coolify インストール
  ↓
インストール確認 → Docker ps, cloud-init ログ
  ↓
セットアップ完了情報を表示
  ↓
Coolify ダッシュボード: http://192.168.0.30:8000
```

---

## 次のステップ

1. 上記の必須 Secrets を GitHub に設定（`PROXMOX_MONAKA_IP` は設定不要）
2. ワークフローを実行
3. Coolify ダッシュボードにアクセス
4. 定期実行スケジュールの設定（オプション）

