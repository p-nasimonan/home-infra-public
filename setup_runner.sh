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
# Add cloudflare gpg key
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add this repo to your apt repositories
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

# install cloudflared
sudo apt-get update && sudo apt-get install cloudflared


# github runnerのインストール
# Create a folder
