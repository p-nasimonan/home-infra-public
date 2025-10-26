#!/bin/bash
# ==========================================
# GitHub Actions Self-Hosted Runner セットアップ
# ==========================================
# このスクリプトは infra-runner LXC 内で実行してください
#
# 前提条件:
# 1. GitHub リポジトリの Settings > Actions > Runners で "New self-hosted runner" をクリック
# 2. Linux x64 を選択し、表示される TOKEN をメモ
# 3. このスクリプトを実行: bash setup_github_runner.sh <GITHUB_TOKEN>

set -e

if [ -z "$1" ]; then
    echo "Error: GitHub runner token が指定されていません"
    echo "Usage: bash setup_github_runner.sh <GITHUB_TOKEN>"
    echo ""
    echo "GitHub runner token の取得方法:"
    echo "1. https://github.com/p-nasimonan/home-infra/settings/actions/runners/new にアクセス"
    echo "2. Linux x64 を選択"
    echo "3. 表示される TOKEN をコピー"
    exit 1
fi

GITHUB_TOKEN="$1"
RUNNER_NAME="infra-runner"
REPO_URL="https://github.com/p-nasimonan/home-infra"
RUNNER_VERSION="2.321.0"  # 最新版を確認: https://github.com/actions/runner/releases

echo "=================================="
echo "GitHub Actions Runner セットアップ"
echo "=================================="

# システム更新
echo "[1/7] システムパッケージを更新中..."
apt-get update
apt-get upgrade -y

# 必要なパッケージをインストール
echo "[2/7] 基本パッケージをインストール中..."
apt-get install -y curl jq tar ca-certificates gnupg

# Node.js のインストール (GitHub Actions と Terraform setup action で必要)
echo "[3/7] Node.js をインストール中..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    echo "✅ Node.js $(node --version) をインストールしました"
else
    echo "✅ Node.js $(node --version) は既にインストールされています"
fi

# runner ユーザーを作成
echo "[4/7] runner ユーザー作成中..."
if ! id -u github-runner > /dev/null 2>&1; then
    useradd -m -s /bin/bash github-runner
    echo "✅ github-runner ユーザーを作成しました"
else
    echo "✅ github-runner ユーザーは既に存在します"
fi

# runner をダウンロード
echo "[5/7] GitHub Actions Runner をダウンロード中..."
cd /home/github-runner
if [ ! -d "actions-runner" ]; then
    mkdir -p actions-runner
fi
cd actions-runner

# 最新版をダウンロード（既にある場合はスキップ）
if [ ! -f "config.sh" ]; then
    echo "Runner v${RUNNER_VERSION} をダウンロード中..."
    curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    echo "✅ Runner をダウンロードしました"
else
    echo "✅ Runner は既にダウンロード済みです"
fi

# 所有権を変更
chown -R github-runner:github-runner /home/github-runner/actions-runner

# runner を設定（runner ユーザーで実行）
echo "[6/7] Runner を設定中..."
sudo -u github-runner bash -c "cd /home/github-runner/actions-runner && ./config.sh --url ${REPO_URL} --token ${GITHUB_TOKEN} --name ${RUNNER_NAME} --work _work --labels self-hosted,Linux,X64,terraform,proxmox --unattended --replace"

# systemd サービスをインストール
echo "[7/7] systemd サービスをインストール中..."
cd /home/github-runner/actions-runner
./svc.sh install github-runner

# サービスを起動・自動起動設定
echo "Runner サービスを起動中..."
./svc.sh start

# ステータス確認
sleep 2
./svc.sh status

echo ""
echo "=================================="
echo "✅ セットアップ完了！"
echo "=================================="
echo ""
echo "インストールされたソフトウェア:"
echo "  Node.js: $(node --version)"
echo "  npm: $(npm --version)"
echo ""
echo "Runner 情報:"
echo "  名前: ${RUNNER_NAME}"
echo "  リポジトリ: ${REPO_URL}"
echo "  ラベル: self-hosted, Linux, X64, terraform, proxmox"
echo "  ユーザー: github-runner"
echo ""
echo "サービス管理コマンド:"
echo "  状態確認: cd /home/github-runner/actions-runner && sudo ./svc.sh status"
echo "  開始: cd /home/github-runner/actions-runner && sudo ./svc.sh start"
echo "  停止: cd /home/github-runner/actions-runner && sudo ./svc.sh stop"
echo "  再起動: cd /home/github-runner/actions-runner && sudo ./svc.sh restart"
echo ""
echo "ログ確認:"
echo "  sudo journalctl -u actions.runner.p-nasimonan-home-infra.infra-runner.service -f"
echo ""
echo "Runner の削除:"
echo "  1. サービス停止: cd /home/github-runner/actions-runner && sudo ./svc.sh stop"
echo "  2. アンインストール: cd /home/github-runner/actions-runner && sudo ./svc.sh uninstall"
echo "  3. 登録解除: sudo -u github-runner ./config.sh remove --token <NEW_TOKEN>"
echo ""
echo "GitHub で確認:"
echo "  https://github.com/p-nasimonan/home-infra/settings/actions/runners"
echo ""
