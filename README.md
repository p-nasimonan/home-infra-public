# Home Infrastructure as Code

Terraform + Ansible + ArgoCD + GitHub Actions で自宅 K3s クラスタを完全自動化するリポジトリです。

## 🎯 アーキテクチャ

```
【GitHub Actions】(CI/CD)
     ↓
【Terraform】→【Proxmox】→【VMs】
     ↓
【Ansible】→【K3s HA Cluster】(kube-vip)
     ↓          ├─ 3x Control Plane (etcd)
【ArgoCD】 　    ├─ 2x Worker Nodes
     ↓          └─ AdGuard Home (LXC)
【Kubernetes Apps】
     ↓
【Cloudflare Tunnel】→【インターネット】
```

**特徴**
- 🏗️ **Infrastructure as Code**: Terraform + Ansible
- 🔄 **GitOps**: ArgoCD による宣言的デプロイ
- 🔒 **HA構成**: kube-vip による仮想 IP フェイルオーバー
- ⚙️ **完全自動化**: GitHub Actions で CI/CD

## 🚀 構成

- **Proxmox VE**: 3x Control Plane + 2x Worker VMs
- **K3s**: HA embedded etcd + kube-vip
- **ArgoCD**: GitOps デプロイメント
- **AdGuard Home**: DNS フィルタリング (LXC)

## ⚡ クイックスタート

### GitHub Actions でデプロイ

Actions → `deploy_to_runner` → `Run workflow`

**パラメータ**:
- `terraform_action`: `plan` / `apply` / `destroy`
- `ansible_target`: `k3s_setup` / `argocd_install`


## 🔑 GitHub Secrets

| Secret | 説明 |
|--------|------|
| `PROXMOX_API_URL` | Proxmox API URL |
| `PROXMOX_TOKEN_ID` | API Token ID |
| `PROXMOX_TOKEN_SECRET` | API Token Secret |
| `PROXMOX_VE_SSH_PRIVATE_KEY` | SSH private key |
| `SSH_PUBLIC_KEY` | SSH public key |
| `UBUNTU_PASSWORD` | VM password |
| `TERRAFORM_CLOUD_TOKEN` | Terraform Cloud token |

## 📦 デプロイフロー

1. **インフラ構築**: GitHub Actions → Terraform → Proxmox VMs 作成
2. **K3s セットアップ**: Ansible → K3s HA クラスタ + kube-vip
3. **ArgoCD 導入**: Ansible → ArgoCD インストール
4. **アプリデプロイ**: `home-manifests` リポジトリに push → ArgoCD 自動同期

## 🔗 関連リポジトリ

- **Application Manifests**: https://github.com/p-nasimonan/home-manifests

