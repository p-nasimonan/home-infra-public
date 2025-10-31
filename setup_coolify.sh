#!/bin/bash
set -e

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Coolify セットアップ自動化スクリプト ===${NC}"
echo ""

# Step 1: クラウドイメージのダウンロード確認
echo -e "${YELLOW}Step 1: クラウドイメージの確認${NC}"
read -p "Proxmox monaka node のIPアドレスを入力: " MONAKA_IP

ssh root@$MONAKA_IP "
  mkdir -p /var/lib/vz/template/iso
  if [ ! -f /var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img ]; then
    echo 'クラウドイメージをダウンロード中...'
    cd /var/lib/vz/template/iso
    wget -q https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
    echo 'ダウンロード完了'
  else
    echo 'クラウドイメージは既に存在します'
  fi
"

echo -e "${GREEN}✓ Step 1 完了${NC}"
echo ""

# Step 2: Terraform apply
echo -e "${YELLOW}Step 2: Terraform で VM を作成（自動IPアドレス生成）${NC}"
cd /Users/e245719/Documents/GitHub/home-infra

terraform apply -target=proxmox_virtual_environment_vm.coolify -auto-approve

# VM のIP取得
COOLIFY_IP=$(terraform output -raw coolify_vm_ip)
echo -e "${GREEN}✓ VM 作成完了: $COOLIFY_IP${NC}"
echo ""

# Step 3: VM の起動を待機
echo -e "${YELLOW}Step 3: VM の起動を待機中...（60秒待機）${NC}"
sleep 60

# Step 4: SSH 接続テスト
echo -e "${YELLOW}Step 4: SSH 接続テスト${NC}"
for i in {1..5}; do
  if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$COOLIFY_IP "echo 'SSH OK'" 2>/dev/null; then
    echo -e "${GREEN}✓ SSH 接続成功${NC}"
    break
  else
    echo "接続試行 $i/5 失敗、再試行..."
    sleep 10
  fi
done

echo ""

# Step 5: Ansible 実行
echo -e "${YELLOW}Step 5: Ansible で Coolify をインストール${NC}"
cd /Users/e245719/Documents/GitHub/home-infra/ansible

# Ping テスト
ansible all -i inventory.ini -m ping || {
  echo -e "${RED}✗ Ansible ping 失敗${NC}"
  exit 1
}

# Playbook 実行
ansible-playbook -i inventory.ini playbook-coolify.yml -v

echo ""
echo -e "${GREEN}=== セットアップ完了 ===${NC}"
echo -e "Coolify ダッシュボード: ${YELLOW}http://$COOLIFY_IP:8000${NC}"
echo ""
