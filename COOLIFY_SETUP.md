# Coolify VM セットアップ手順

Terraform + Ansible を使用したCoolify自動デプロイメント

## 前提条件

- Ansible がローカルマシンにインストール済み
  ```bash
  brew install ansible
  ```

---

## Step 1: クラウドイメージをProxmoxにダウンロード

Proxmoxノード（monaka）にSSH接続して、Ubuntuクラウドイメージをダウンロードします。

```bash
# Proxmox monaka nodeにSSH接続
ssh root@monaka.youkan.uk

# ディレクトリ作成
mkdir -p /var/lib/vz/template/iso

# Ubuntuクラウドイメージをダウンロード（約500MB）
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# ダウンロード確認
ls -lh jammy-server-cloudimg-amd64.img
```

**所要時間**: ネット速度による（5-15分程度）

---

## Step 2: Terraform で VM を作成

ローカルマシン上でTerraformを実行してVMを作成します。

```bash
cd /Users/e245719/Documents/GitHub/home-infra

# Terraform プランを確認
terraform plan -target=proxmox_virtual_environment_vm.coolify

# VM を作成
terraform apply -target=proxmox_virtual_environment_vm.coolify

# VM のIPアドレスを確認
terraform output coolify_info
```

**出力例:**
```
coolify_info = {
  "ipv4" = "192.168.0.30"
  "name" = "coolify"
  "node" = "monaka"
  "vm_id" = 102
}
```

**所要時間**: 2-3分

---

## Step 3: Ansible Inventory を更新

Ansible が VM に接続するための設定を更新します。

`ansible/inventory.ini` を開いて、`coolify-vm` のIPアドレスを Step 2 で取得したIPに置き換えます：

```ini
[coolify]
# Terraform output から取得したIPに置き換える
coolify-vm ansible_host=192.168.0.30 ansible_user=ubuntu ansible_password=Coolify2024!

[coolify:vars]
ansible_connection=ssh
ansible_port=22
```

---

## Step 4: Ansible で接続テスト

```bash
cd /Users/e245719/Documents/GitHub/home-infra/ansible

# Ping テスト（接続確認）
ansible all -i inventory.ini -m ping
```

**期待される出力:**
```
coolify-vm | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

---

## Step 5: Ansible で Coolify をインストール

Ansible Playbook で Docker と Coolify を自動インストールします。

```bash
cd /Users/e245719/Documents/GitHub/home-infra/ansible

# Playbook を実行（verbose モードで進捗確認）
ansible-playbook -i inventory.ini playbook-coolify.yml -v
```

**所要時間**: 5-10分

---

## Step 6: インストール確認

### SSH で VM にログイン

```bash
ssh ubuntu@192.168.0.30
# パスワード: Coolify2024!
```

### Docker が起動しているか確認

```bash
docker ps
docker ps -a  # 全コンテナ表示
```

### Coolify のログを確認

```bash
docker logs $(docker ps | grep coolify | awk '{print $1}') 2>&1 | head -50
```

---

## Step 7: Coolify ダッシュボードにアクセス

ブラウザで以下にアクセス:

```
http://192.168.0.30:8000
```

初期セットアップウィザードに従い、Coolify ダッシュボードを設定します。

---

## トラブルシューティング

### Ansible が VM に接続できない

```bash
# SSH で直接接続確認
ssh -v ubuntu@192.168.0.30

# ファイアウォール確認
sudo ufw status
```

### Docker が起動していない

```bash
ssh ubuntu@192.168.0.30
sudo systemctl status docker
sudo systemctl restart docker
```

### Coolify が起動していない

```bash
ssh ubuntu@192.168.0.30
docker ps -a
docker logs $(docker ps -aq)
```

---

## ファイル構成

```
.
├── vms.tf                              # VM定義
├── ansible/
│   ├── inventory.ini                  # ホスト定義
│   ├── inventory.tpl                  # ホスト定義テンプレート
│   ├── playbook-coolify.yml           # Coolify インストール Playbook
│   └── README.md                      # Ansible 詳細ドキュメント
├── .github/workflows/
│   └── setup-coolify.yml              # GitHub Actions ワークフロー
└── COOLIFY_SETUP.md                   # このファイル
```

---

## 次のステップ

1. **Coolify ダッシュボード設定**
   - データーベース設定
   - SSH キー登録
   - アプリケーション設定

2. **Cloudflare Tunnel へ Coolify を追加**（オプション）
   - `variables.tf` の `services` に Coolify を追加
   - HTTPS でアクセス可能にする

3. **定期メンテナンス**
   - Ansible Playbook で周期的に更新実行
   - Docker コンテナのメンテナンス

---

## GitHub Actions で全自動化（オプション）

`.github/workflows/setup-coolify.yml` ワークフロー で以下が自動実行されます：

1. クラウドイメージをProxmoxにダウンロード
2. Terraform で VM を作成
3. Ansible で Coolify をインストール
4. インストール完了通知

実行方法：

```
GitHub → Actions → Coolify セットアップ自動化 → Run workflow
```
