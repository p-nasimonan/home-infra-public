# Home Infrastructure as Code

Terraform + Ansible + ArgoCD + GitHub Actions で自宅インフラ(K3s + GitOps)を完全自動化するリポジトリです。

## 🎯 アーキテクチャ

```
【Git リポジトリ】(このリポジトリ)
     ↓ (Application manifests)
【GitHub Actions】(CI/CD)
     ↓ (terraform / ansible)
【Terraform】→【Proxmox】
          ↓
【Ansible】→【K3s Cluster】
          ↓
【ArgoCD】→【Applications】
     ↓       ├─ Cloudflare Tunnel Ingress Controller
【Kubernetes】 ├─ Rancher
              ├─ その他 Apps
              └─ ...
     ↓
【Cloudflare Edge】
     ↓
【インターネット】 (ゼロトラスト)
```

**特徴**
- 🏗️ **Infrastructure as Code**: Terraform で VM 構成を自動化
- 🔄 **GitOps**: ArgoCD で Kubernetes リソースを Git 管理
- 🔒 **ゼロトラスト**: Cloudflare Tunnel でセキュア公開
- ⚙️ **完全自動化**: GitHub Actions で CI/CD パイプライン

## 🚀 概要

このプロジェクトでは以下を管理します:

- **Proxmox VE**: 3台 VMs (K3s HA cluster)
- **K3s Kubernetes**: HA embedded etcd (3ノード)
- **Rancher**: K3s-server-1 上に Helm でインストール
- **ArgoCD**: K3s-server-1 上に Helm でインストール（GitOps）
- **Cloudflare Tunnel**: Ingress Controller 経由で公開
- **Terraform**: Infrastructure as Code (Proxmox VMs)
- **Ansible**: K3s + Rancher + ArgoCD 自動デプロイ
- **GitHub Actions**: CI/CD パイプライン（self-hosted runner）

## 📂 ディレクトリ構成

```
home-infra/
├── README.md                          # このファイル
├── terraform.tfvars.example           # Terraform 変数（テンプレート）
├── variables.tf                       # 変数定義
├── providers.tf                       # Terraform providers
├── data-sources.tf                    # データソース
├── network_zones.tf                   # ネットワーク設定
├── vms.tf                             # VMs (K3s + Rancher)
├── outputs.tf                         # 出力値
│
├── ansible/                           # Ansible playbooks
│   ├── inventory.yml                  # ホスト定義
│   ├── requirements.yml               # ロール/コレクション
│   ├── playbook-k3s-setup.yml         # K3s + Rancher デプロイ
│   └── playbook-argocd-install.yml    # ArgoCD インストール
│
└── .github/workflows/
    ├── deploy_to_runner.yml           # Terraform + Ansible 本番デプロイ
    └── ci-validate.yml                # CI 検証
```

## ⚡ クイックスタート

### 前提条件

- Self-hosted GitHub Runner（Proxmox ホストまたは専用マシン上）
- GitHub Actions 対応リポジトリ
- SSH キーペア（Proxmox/VM アクセス用）

### ワークフロー実行

すべてのデプロイは **GitHub Actions** 経由で実行します。リポジトリの Actions タブから以下を実行：

#### 1️⃣ `deploy_to_runner` Workflow で Terraform + Ansible をデプロイ

Actions → `deploy_to_runner` → `Run workflow`

**入力パラメータ**:
- `terraform_action`: `plan`, `apply`, `destroy` から選択
- `ansible_target`: `k3s_setup` または `argocd_install`

**実行内容**:
- Terraform で 3 × K3s servers + 1 × Rancher server VM を作成
- Ansible で K3s + Rancher をセットアップ
- 全て自動で実行（ローカル実行は不要）

#### 2️⃣ ArgoCD に Git リポジトリを登録

ArgoCD UI にて `home-manifests` リポジトリを登録:
```
Repo: https://github.com/p-nasimonan/home-manifests
```

#### 3️⃣ アプリケーション自動デプロイ

`home-manifests` リポジトリに Application manifests を push すると、ArgoCD が自動で同期します。

## 🔑 GitHub Secrets 設定

リポジトリ Settings → Secrets and variables → Actions で以下を設定:

| Secret 名 | 説明 | 用途 |
|----------|------|------|
| `PROXMOX_API_URL` | Proxmox API URL (https://xxx.xxx.x.xx:8006/api2/json) | deploy_to_runner workflow |
| `PROXMOX_TOKEN_ID` | Proxmox API Token ID | deploy_to_runner workflow |
| `PROXMOX_TOKEN_SECRET` | Proxmox API Token Secret | deploy_to_runner workflow |
| `PROXMOX_VE_SSH_PRIVATE_KEY` | SSH private key（Proxmox/VMs へのアクセス用） | Ansible ステップ |
| `SSH_PUBLIC_KEY` | SSH public key | Terraform（VM キー設定） |
| `UBUNTU_PASSWORD` | Ubuntu VM password | Terraform（VM 初期設定） |
| `TERRAFORM_CLOUD_TOKEN` | Terraform Cloud API token | Terraform Cloud state 管理 |


## 📋 インベントリ設定（inventory.yml）

```yaml
# K3s クラスタ (3台 HA)
[k3s_servers]
k3s-server-1 ansible_host=192.168.0.20 ansible_user=youkan
k3s-server-2 ansible_host=192.168.0.21 ansible_user=youkan
k3s-server-3 ansible_host=192.168.0.22 ansible_user=youkan

# Rancher 管理サーバ
[rancher_servers]
rancher-server ansible_host=192.168.0.30 ansible_user=youkan
```

## 🔄 GitOps ワークフロー（推奨）

このリポジトリは **Infrastructure as Code** （Terraform + Ansible）を管理します。

Kubernetes Application manifests は別リポジトリ **`home-manifests`** で管理します：
https://github.com/p-nasimonan/home-manifests

### Application 追加手順

**1. `home-manifests` リポジトリに Application manifest を作成**

```bash
# home-manifests リポジトリで実行
mkdir -p applications/myapp
cat > applications/myapp/application.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.example.com
    chart: myapp
    targetRevision: "1.0.0"
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

**2. Git にコミット & push**

```bash
git add applications/
git commit -m "feat: add myapp application"
git push origin main
```

**3. ArgoCD が自動同期**

- ArgoCD は `home-manifests` リポジトリを監視
- push されたら自動で同期開始
- myapp が `Synced` ✅

### ワークフロー分割

| リポジトリ | 用途 |
|----------|------|
| **home-infra** (このリポ) | Terraform + Ansible（インフラ構成）|
| **home-manifests** | Kubernetes Applications（GitOps）|

以後は **Git push だけで自動デプロイ** ✨

## 🔗 参考リンク

- [Terraform Proxmox Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

---

## 📍 別リポジトリ

- **Application Manifests**: https://github.com/p-nasimonan/home-manifests
