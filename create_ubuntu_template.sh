#!/bin/bash
# Ubuntu Cloud Image テンプレート作成スクリプト
# Proxmox ノード上で root として実行

set -e

TEMPLATE_ID=9000
TEMPLATE_NAME="ubuntu-22.04-template"
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_FILE="jammy-server-cloudimg-amd64.img"

echo "========================================="
echo "Ubuntu Cloud Image テンプレート作成"
echo "========================================="

# テンプレートが既に存在するかチェック
if qm status $TEMPLATE_ID &>/dev/null; then
  echo "⚠️  VMID $TEMPLATE_ID は既に存在します"
  echo "削除して再作成しますか？ (y/N)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "既存のテンプレートを削除中..."
    qm destroy $TEMPLATE_ID
  else
    echo "処理を中止しました"
    exit 0
  fi
fi

# 1. クラウドイメージをダウンロード
echo ""
echo "ステップ 1: クラウドイメージのダウンロード"
cd /var/lib/vz/template/iso

if [ -f "$IMAGE_FILE" ]; then
  echo "✓ イメージは既に存在します: $IMAGE_FILE"
else
  echo "ダウンロード中: $IMAGE_URL"
  wget -q --show-progress "$IMAGE_URL"
  echo "✓ ダウンロード完了"
fi

# 2. テンプレートVM作成
echo ""
echo "ステップ 2: テンプレートVM作成 (VMID: $TEMPLATE_ID)"
qm create $TEMPLATE_ID \
  --name "$TEMPLATE_NAME" \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci

echo "✓ VM作成完了"

# 3. クラウドイメージをインポート
echo ""
echo "ステップ 3: ディスクイメージをインポート"
qm importdisk $TEMPLATE_ID "$IMAGE_FILE" local-lvm

echo "✓ インポート完了"

# 4. ディスクをアタッチ
echo ""
echo "ステップ 4: ディスク設定"
qm set $TEMPLATE_ID --scsi0 local-lvm:vm-${TEMPLATE_ID}-disk-0
qm set $TEMPLATE_ID --ide2 local-lvm:cloudinit
qm set $TEMPLATE_ID --boot order=scsi0
qm set $TEMPLATE_ID --serial0 socket --vga serial0
qm set $TEMPLATE_ID --agent enabled=1

echo "✓ ディスク設定完了"

# 5. テンプレート化
echo ""
echo "ステップ 5: テンプレート化"
qm template $TEMPLATE_ID

echo ""
echo "========================================="
echo "✅ テンプレート作成完了"
echo "========================================="
echo "テンプレート VMID: $TEMPLATE_ID"
echo "テンプレート名: $TEMPLATE_NAME"
echo ""
echo "このテンプレートからVMをクローンできます:"
echo "  qm clone $TEMPLATE_ID <new-vmid> --name <vm-name> --full"
echo ""
echo "Terraform では以下のように使用:"
echo "  clone {"
echo "    vm_id = $TEMPLATE_ID"
echo "    full  = true"
echo "  }"
echo "========================================="
