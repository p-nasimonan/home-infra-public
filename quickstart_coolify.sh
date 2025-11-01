#!/bin/bash
# Coolify セットアップ - クイックスタート
# このスクリプトはローカルマシンから実行します

set -e


REPO_DIR="/Users/e245719/Documents/GitHub/home-infra"

echo "========================================="
echo "Coolify VM セットアップ - クイックスタート"
echo "========================================="
echo ""

# 1. テンプレート確認
echo "ステップ 1: テンプレート確認"
if ssh monaka "qm status 9000" &>/dev/null; then
  echo "✓ Ubuntu テンプレート (9000) は既に存在します"
else
  echo "⚠️  テンプレートが存在しません。作成しますか？ (y/N)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "テンプレート作成スクリプトを転送中..."
    scp "$REPO_DIR/create_ubuntu_template.sh" monaka:/root/
    
    echo "テンプレートを作成中（約3-5分）..."
    ssh monaka "bash /root/create_ubuntu_template.sh"
    echo "✓ テンプレート作成完了"
  else
    echo "❌ テンプレートが必要です。中止します。"
    exit 1
  fi
fi

# 2. cloud-init配置
echo ""
echo "ステップ 2: cloud-init 設定を配置"
scp "$REPO_DIR/cloud-init/coolify-init.yaml" monaka:/var/lib/vz/snippets/
echo "✓ cloud-init 配置完了"

# 3. 既存VM削除確認
echo ""
echo "ステップ 3: 既存VM削除"
if ssh monaka "qm status 106" &>/dev/null; then
  echo "⚠️  VM 106 (coolify) が存在します。削除しますか？ (y/N)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "VM 106 を停止・削除中..."
    ssh monaka "qm stop 106 2>/dev/null || true"
    ssh monaka "qm destroy 106"
    echo "✓ VM削除完了"
  fi
else
  echo "✓ VM 106は存在しません（新規作成）"
fi

# 4. Git commit & push
echo ""
echo "ステップ 4: 変更をコミット"
cd "$REPO_DIR"

# 変更があるかチェック
if [[ -n $(git status -s) ]]; then
  echo "変更されたファイル:"
  git status -s
  echo ""
  echo "これらの変更をコミットしますか？ (y/N)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    git add vms.tf cloud-init/ create_ubuntu_template.sh *.md
    git commit -m "Fix: Use Ubuntu template for Coolify VM with proper OS installation"
    git push
    echo "✓ Git push完了"
  fi
else
  echo "✓ 変更はありません（既にpush済み）"
fi

# 5. GitHub Actions起動
echo ""
echo "ステップ 5: GitHub Actions で自動デプロイ"
echo ""
echo "以下のURLにアクセスして、Workflowを実行してください:"
echo "https://github.com/p-nasimonan/home-infra/actions/workflows/setup-coolify.yml"
echo ""
echo "実行手順:"
echo "  1. 'Run workflow' ボタンをクリック"
echo "  2. action: 'setup' を選択"
echo "  3. 'Run workflow' を実行"
echo ""
echo "または、gh CLI がインストールされている場合:"
echo "  gh workflow run setup-coolify.yml -f action=setup"
echo ""

# 6. 完了メッセージ
echo "========================================="
echo "✅ 準備完了"
echo "========================================="
echo ""
echo "次のステップ:"
echo "  1. GitHub Actions でワークフローを実行"
echo "  2. 実行完了を待つ（約10-15分）"
echo "  3. VM IPアドレスを確認"
echo "  4. Web UI にアクセス: http://<vm-ip>:8000"
echo ""
echo "確認コマンド:"
echo "  ssh monaka 'qm status 106'"
echo "  ssh monaka 'qm guest cmd 106 network-get-interfaces'"
echo ""
echo "========================================="
