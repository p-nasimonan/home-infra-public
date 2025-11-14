#!/bin/bash
set -e

# 1. タイムゾーンの設定 (JST)
timedatectl set-timezone Asia/Tokyo

# パッケージリストを更新/最新に
apt update && apt upgrade -y

# QEMU Guest Agentをインストール
apt install -y qemu-guest-agent

# サービスが自動起動するように有効化
systemctl enable qemu-guest-agent

# サービスをすぐに開始
systemctl start qemu-guest-agent

# K3sとAnsibleに必要なパッケージのインストール
apt install -y curl sshpass

# SWAPの無効化 (Kubernetesの必須要件)
swapoff -a
sed -i '/swap/d' /etc/fstab