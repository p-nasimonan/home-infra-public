# Terraform + Ansible での Coolify セットアップ

## セットアップ手順

### 1. クラウドイメージをProxmoxにダウンロード

```bash
# monaka nodeにSSH接続
ssh root@<monaka-node-ip>

# クラウドイメージをダウンロード
mkdir -p /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img \
  -O /var/lib/vz/template/iso/ubuntu-22.04-cloudimg.img
```

### 2. Terraform で VM を作成

```bash
cd /Users/e245719/Documents/GitHub/home-infra
terraform apply -target=proxmox_virtual_environment_vm.coolify
```

出力から VM の IP アドレスを確認：
```bash
terraform output coolify_vm_ip
```

### 3. Ansible インベントリを更新

`ansible/inventory.ini` の `coolify-vm` ホスト定義の `ansible_host` を、 VM の IP に置き換える：

```ini
[coolify]
coolify-vm ansible_host=192.168.0.XX ansible_user=ubuntu ansible_password=Coolify2024!
```

### 4. Ansible でセットアップを実行

```bash
cd /Users/e245719/Documents/GitHub/home-infra/ansible

# インベントリ接続テスト
ansible all -i inventory.ini -m ping

# Playbook 実行
ansible-playbook -i inventory.ini playbook-coolify.yml -v
```

## 動作確認

### SSH でログイン

```bash
ssh ubuntu@<coolify-vm-ip>
# パスワード: Coolify2024!
```

### Docker が起動しているか確認

```bash
docker ps
```

### Coolify ダッシュボードにアクセス

```
http://<coolify-vm-ip>:8000
```

## Ansible コマンド例

### 全ホストの接続確認
```bash
ansible all -i inventory.ini -m ping
```

### 全ホストでコマンド実行
```bash
ansible all -i inventory.ini -m shell -a "uptime"
```

### 特定ホストで実行
```bash
ansible coolify-vm -i inventory.ini -m shell -a "docker ps"
```

### Playbook を実行
```bash
ansible-playbook -i inventory.ini playbook-coolify.yml
```

### Playbook の構文チェック
```bash
ansible-playbook -i inventory.ini playbook-coolify.yml --syntax-check
```

## Ansible をインストール（ローカルマシン）

```bash
# macOSの場合
brew install ansible

# または
pip3 install ansible
```

確認：
```bash
ansible --version
```

## ファイル構成

```
ansible/
├── inventory.ini              # ホスト定義
├── playbook-coolify.yml      # Coolifyインストール用Playbook
└── README.md                 # このファイル
```

## トラブルシューティング

### SSH 接続エラー
```
"Failed to connect to the host via ssh"
```
→ `ansible_host` が正しいか確認、ファイアウォール設定を確認

### パスワード認証エラー
```
"Permission denied (publickey,password)"
```
→ `ansible_password` が正しいか確認、SSH の `PasswordAuthentication` が有効か確認

### Ansible がインストールされていない
```bash
pip3 install ansible
```

## 次のステップ

- Ansible で定期的なログ収集設定
- Cloudflare Tunnel への Coolify サービス登録
- Coolify Dashboard での アプリケーション設定
