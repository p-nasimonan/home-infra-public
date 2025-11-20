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

- **Proxmox VE**: 3台 VMs (K3s cluster)
- **K3s Kubernetes**: HA embedded etcd + Rancher
- **ArgoCD**: GitOps ベースのアプリケーション管理
- **Cloudflare Tunnel**: Ingress Controller 経由で公開
- **Terraform**: Infrastructure as Code (Proxmox VMs)
- **Ansible**: K3s + Rancher + ArgoCD 自動デプロイ
- **GitHub Actions**: CI/CD パイプライン

## 📂 ディレクトリ構成

```
home-infra/
├── README.md                          # このファイル
├── QUICKSTART.md                      # クイックスタート
├── CLOUDFLARE_TUNNEL_SETUP.md         # Tunnel Ingress セットアップガイド
├── ARGOCD_GITOPS_SETUP.md             # ArgoCD GitOps セットアップガイド
├── terraform.tfvars                   # Terraform 変数（本番）
├── terraform.tfvars.example           # Terraform 変数（テンプレート）
├── variables.tf                       # 変数定義
├── providers.tf                       # Terraform providers
│
├── cloudflare/                        # Cloudflare リソース
│   ├── dns.tf                         # DNS レコード
│   ├── tunnel.tf                      # Tunnel 設定
│   └── outputs.tf                     # 出力値
│
├── proxmox/                           # Proxmox リソース
│   ├── vms.tf                         # VMs (K3s + Rancher)
│   ├── network.tf                     # ネットワーク設定
│   └── outputs.tf                     # 出力値
│
├── ansible/                           # Ansible playbooks
│   ├── inventory.yml                  # ホスト定義
│   ├── requirements.yml               # ロール/コレクション
│   ├── playbook-k3s-setup.yml         # K3s + Rancher デプロイ（メイン）
│   ├── playbook-argocd-install.yml    # ArgoCD インストール
│   ├── playbook-argocd-cloudflare-tunnel.yml  # Tunnel Ingress (GitOps)
│   └── roles/                         # カスタムロール（オプション）
│
├── applications/                      # Kubernetes Applications (GitOps)
│   ├── cloudflare-tunnel-ingress/     # Cloudflare Tunnel Ingress Controller
│   │   └── application.yaml
│   ├── rancher/                       # Rancher
│   │   └── application.yaml
│   └── app-of-apps.yaml               # 親 Application（全アプリ管理）
│
└── .github/workflows/
    ├── terraform-plan.yml             # Terraform 計画
    └── ansible-k3s-deploy.yml         # Ansible 本番デプロイ
```

## ⚡ クイックスタート

### 前提条件

- Proxmox VE ホスト（3台推奨）
- Cloudflare account
- Terraform 1.13+
- Ansible 2.9+
- GitHub Actions 対応リポジトリ

### 1️⃣ Terraform で VMs を作成

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**出力**: 3 × K3s servers + 1 × Rancher server VM

### 2️⃣ Cloudflare Tunnel を作成

```bash
# ローカルマシンで実行
cloudflared tunnel login
cloudflared tunnel create k3s-rancher
cloudflared tunnel route dns k3s-rancher rancher.youkan.uk
cloudflared tunnel route dns k3s-rancher argocd.youkan.uk
```

### 3️⃣ Ansible で K3s + Rancher をデプロイ

```bash
cd ansible
ansible-playbook -i inventory.yml playbook-k3s-setup.yml \
  -e "rancher_password=YourSecurePassword123!"
```

または GitHub Actions: `ansible-k3s-deploy` workflow を実行

### 4️⃣ ArgoCD をインストール

```bash
# ローカルで実行
ansible-playbook -i ansible/inventory.yml ansible/playbook-argocd-install.yml \
  -e "argocd_password=YourSecurePassword123!"
```

または GitHub Actions: `ansible-argocd-install` workflow を実行

### 5️⃣ アプリケーション自動デプロイ設定

```bash
# Git リポジトリを ArgoCD に登録
argocd repo add https://github.com/youkan0124/home-infra

# App of Apps で全アプリケーション管理
kubectl apply -f applications/app-of-apps.yaml
```

### 6️⃣ アクセス

```
Rancher: https://rancher.youkan.uk
ArgoCD:  https://argocd.youkan.uk
```

> 詳細は [ARGOCD_GITOPS_SETUP.md](ARGOCD_GITOPS_SETUP.md) と [CLOUDFLARE_TUNNEL_SETUP.md](CLOUDFLARE_TUNNEL_SETUP.md) を参照

## 🔑 GitHub Secrets 設定

リポジトリ Settings → Secrets and variables → Actions で以下を設定:

| Secret 名 | 説明 | 用途 |
|----------|------|------|
| `TERRAFORM_BACKEND_PASS` | Terraform Cloud API token | terraform-plan workflow |
| `PROXMOX_TOKEN_ID` | Proxmox API Token ID | terraform-plan workflow |
| `PROXMOX_TOKEN_SECRET` | Proxmox API Token Secret | terraform-plan workflow |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token | terraform-plan workflow |
| `RANCHER_PASSWORD` | Rancher bootstrap password | ansible-k3s-deploy workflow |
| `ARGOCD_PASSWORD` | ArgoCD admin password | ansible-argocd-install workflow |
| `ANSIBLE_SSH_PRIVATE_KEY` | SSH private key | 全 Ansible workflow |


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

### Application 追加手順

**1. Application manifest を作成**
```bash
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

**2. Kustomization に追加**
```yaml
# applications/kustomization.yaml
resources:
  - cloudflare-tunnel-ingress/application.yaml
  - myapp/application.yaml  # ← 追加
```

**3. Git にコミット**
```bash
git add applications/
git commit -m "feat: add myapp application"
git push origin main
```

**4. ArgoCD が自動同期**
- ArgoCD UI: https://argocd.youkan.uk
- myapp が `Synced` ✅

### ワークフロー分割

| Workflow | ファイル | 用途 |
|----------|---------|------|
| `terraform-plan` | - | Proxmox VMs 計画 |
| `ansible-k3s-deploy` | `playbook-k3s-setup.yml` | K3s + Rancher デプロイ |
| `ansible-argocd-install` | `playbook-argocd-install.yml` | ArgoCD インストール |

以後は **Git push だけで自動デプロイ** ✨

## 🔗 参考リンク

- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Cloudflare Tunnel Ingress](https://github.com/cloudflare/cloudflare-operator)
- [K3s Documentation](https://docs.k3s.io/)
- [Rancher Documentation](https://rancher.com/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Best Practices](https://www.weave.works/blog/gitops-operations-by-pull-request/)
