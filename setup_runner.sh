#!/bin/bash
# ==========================================
# Terraform & Cloudflared Runner セットアップスクリプト
# ==========================================
# このスクリプトは、LXC コンテナ内で実行してください
#
# 使い方:
# 1. LXC にSSH接続: ssh root@<lxc-ip>
# 2. このスクリプトをコピー: curl -O https://raw.githubusercontent.com/...
# 3. 実行: chmod +x setup_runner.sh && ./setup_runner.sh

set -e

echo "=================================="
echo "Terraform & Cloudflared セットアップ"
echo "=================================="

# システム更新
echo "[1/6] システムパッケージを更新中..."
apt-get update
apt-get upgrade -y

# 必要なパッケージをインストール
echo "[2/6] 基本パッケージをインストール中..."
apt-get install -y \
    curl \
    wget \
    git \
    gnupg \
    software-properties-common \
    ca-certificates \
    unzip

# Terraform のインストール
echo "[3/6] Terraform をインストール中..."
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install -y terraform

# Cloudflared のインストール
echo "[4/6] Cloudflared をインストール中..."
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared-linux-amd64.deb
rm cloudflared-linux-amd64.deb

# Git リポジトリをクローン（オプション）
echo "[5/6] 作業ディレクトリを準備中..."
mkdir -p /root/infrastructure
cd /root/infrastructure

# バージョン確認
echo "[6/6] インストール確認..."
echo ""
echo "✅ Terraform バージョン:"
terraform version
echo ""
echo "✅ Cloudflared バージョン:"
cloudflared --version
echo ""
echo "✅ Git バージョン:"
git --version

echo ""
echo "=================================="
echo "✅ セットアップ完了！"
echo "=================================="
echo ""
echo "次のステップ:"
echo "1. Git リポジトリをクローン:"
echo "   cd /root/infrastructure"
echo "   git clone https://github.com/p-nasimonan/home-infra.git"
echo "   cd home-infra"
echo ""
echo "2. Terraform 初期化:"
echo "   terraform init"
echo ""
echo "3. Cloudflared Tunnel を起動:"
echo "   cloudflared tunnel run --token <YOUR_TUNNEL_TOKEN>"
echo ""
echo "4. または、systemd サービスとして登録:"
echo "   cloudflared service install <YOUR_TUNNEL_TOKEN>"
echo "   systemctl start cloudflared"
echo "   systemctl enable cloudflared"
echo ""
