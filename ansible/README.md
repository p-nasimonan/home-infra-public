# K3s Ansible Playbook Setup Guide

このディレクトリには、`xanmanning.k3s` Ansibleロールを使用してK3sクラスタをセットアップするためのプレイブックが含まれています。

## 前提条件

### Ansibleコントローラマシン（実行マシン）での要件

```bash
# Pythonパッケージのインストール
pip3 install -r requirements.txt

# Ansibleロール依存関係のインストール
ansible-galaxy install -r requirements.yml
```

### ターゲットノードの要件

- Ubuntu 22.04 LTS 以上
- SSH接続が可能
- `youkan` ユーザーでのsudo権限（パスワードなし）
- Python 3.x

## ファイル構成

```
ansible/
├── ansible.cfg              # Ansibleの設定ファイル
├── inventory.ini            # インベントリ定義
├── requirements.txt         # Python依存パッケージ
├── requirements.yml         # Ansibleロール依存関係
├── playbook-k3s-setup.yml  # K3sセットアップメインプレイブック
└── README.md               # このファイル
```

## インベントリ構成

### k3s_servers グループ

- **k3s-server-1** (192.168.0.20): Control Plane + etcd node 1
- **k3s-server-2** (192.168.0.21): Control Plane + etcd node 2
- **k3s-server-3** (192.168.0.22): Control Plane + etcd node 3

### rancher_servers グループ

- **rancher-server** (192.168.0.30): 独立したK3s単一ノード（Rancher管理UI用）

## セットアップ手順

### 1. Ansibleコントローラの準備

```bash
cd ansible/

# Python依存関係のインストール
pip3 install -r requirements.txt

# Ansibleロールのインストール
ansible-galaxy install -r requirements.yml
```

### 2. インベントリの確認

```bash
# ホスト接続テスト
ansible all -i inventory.ini -m ping
```

### 3. プレイブック実行（ドライラン）

```bash
# 構文チェック
ansible-playbook -i inventory.ini playbook-k3s-setup.yml --syntax-check

# ドライラン
ansible-playbook -i inventory.ini playbook-k3s-setup.yml --check
```

### 4. K3sクラスタセットアップ実行

```bash
# K3s サーバー (Control Plane) セットアップ
ansible-playbook -i inventory.ini playbook-k3s-setup.yml -l k3s_servers -v

# Rancher サーバー セットアップ
ansible-playbook -i inventory.ini playbook-k3s-setup.yml -l rancher_servers -v

# 全ノードセットアップ
ansible-playbook -i inventory.ini playbook-k3s-setup.yml -v
```

## 重要な設定変数

### グローバル設定（playbook-k3s-setup.yml）

- **k3s_release_version**: K3sリリース版（例：`v1.34.1`）
- **k3s_etcd_datastore**: etcd組み込みデータストア有効化（HA用）
- **k3s_registration_address**: ノード登録用アドレス（`192.168.0.20`）

### K3sサーバー設定（Control Plane）

```yaml
k3s_server:
  disable:
    - servicelb
    - traefik
  flannel-backend: vxlan
  audit-log-maxage: 30
```

### K3sエージェント設定（ワーカー）

```yaml
k3s_agent:
  node-label:
    - "node-role=worker"
```

## 実行後の検証

### 1. K3sクラスタの状態確認

```bash
# k3s-server-1 にSSH接続
ssh youkan@192.168.0.20

# クラスタノード確認
k3s kubectl get nodes

# クラスタの詳細情報
k3s kubectl cluster-info

# Pod確認
k3s kubectl get pods --all-namespaces
```

### 2. Kubeconfigの取得

セットアップ完了後、`kubeconfig.yaml` が Ansible実行ディレクトリに保存されます。

```bash
# ローカルマシンで使用
export KUBECONFIG=./kubeconfig.yaml
kubectl get nodes
```

### 3. 各ノードの確認

```bash
# k3s-server-2 の確認
ssh youkan@192.168.0.21 "k3s kubectl get nodes"

# rancher-server の確認
ssh youkan@192.168.0.30 "k3s kubectl get nodes"
```

## トラブルシューティング

### SSH接続エラー

```bash
# SSH鍵の権限確認
ls -la ~/.ssh/key/ansible
# 権限が600である必要があります
chmod 600 ~/.ssh/key/ansible

# SSH接続テスト
ssh -i ~/.ssh/key/ansible youkan@192.168.0.20
```

### Python 3 インタープリタエラー

```bash
# ターゲットノードで Python 3 が存在するか確認
ssh youkan@192.168.0.20 "which python3"

# もし python3 が見つからない場合
ssh youkan@192.168.0.20 "sudo apt-get install -y python3"
```

### etcd クラスタエラー

etcdが正常に起動しているか確認：

```bash
ssh youkan@192.168.0.20
sudo k3s etcd-snapshot status
k3s kubectl get endpoints -n kube-system
```

### K3s サービス確認

```bash
# サービス状態確認
ssh youkan@192.168.0.20
sudo systemctl status k3s

# ログ確認
sudo journalctl -u k3s -f
```

## 高度な設定

### 外部etcdデータベースの使用

k3s_serverで以下を設定：

```yaml
k3s_server:
  datastore-endpoint: "postgres://user:password@host:5432/database?sslmode=disable"
```

### カスタムマニフェストのデプロイ

```yaml
k3s_server_manifests_urls:
  - url: https://example.com/manifest.yaml
    filename: custom-manifest.yaml

k3s_server_manifests_templates:
  - path/to/template.yaml.j2
```

### ノードラベルの設定

```yaml
k3s_agent:
  node-label:
    - "environment=production"
    - "node-type=compute"
    - "gpu=true"
```

## ドキュメント参照

- [xanmanning.k3s - GitHub](https://github.com/xanmanning/ansible-role-k3s)
- [K3s 公式ドキュメント](https://docs.k3s.io/)
- [K3s インストールオプション](https://rancher.com/docs/k3s/latest/en/installation/)

## ライセンス

このプレイブックはプロジェクトと同じライセンスの下で公開されています。
