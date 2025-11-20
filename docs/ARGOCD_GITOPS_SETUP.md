# ArgoCD GitOps セットアップガイド

Kubernetes cluster を GitOps 方式で管理するための ArgoCD セットアップ手順です。

## 🎯 概要

**構成**
```
【Git リポジトリ】
  ↓ (Application manifest)
【ArgoCD】 (GitOps engine)
  ↓ (監視・自動同期)
【Kubernetes Cluster】
  ├─ Cloudflare Tunnel Ingress Controller
  ├─ Rancher
  ├─ その他アプリ
  └─ ...
```

**メリット**
- ✅ **宣言的管理**: すべてが Git で定義される
- ✅ **自動同期**: クラスタが Git と異なれば自動修正
- ✅ **監査ログ**: Git コミット履歴で全ての変更を追跡
- ✅ **ロールバック**: 簡単に前のバージョンに戻せる
- ✅ **シングルペイン**: 全アプリの状態を UI で一元管理

---

## 🚀 インストール手順

### Step 1: Ansible で ArgoCD をインストール

```bash
# K3s サーバーで実行（via Ansible or GitHub Actions）
ansible-playbook -i ansible/inventory.yml ansible/playbook-k3s-setup.yml \
  -e "argocd_password=YourSecurePassword123!"
```

または GitHub Actions で実行:
```
workflow_dispatch で deploy ボタンを押す
```

### Step 2: ArgoCD UI にアクセス

```
https://argocd.youkan.uk
```

**初回ログイン**
- Username: `admin`
- Password: インストール時に指定したパスワード

### Step 3: CLI をセットアップ（オプション）

```bash
# ArgoCD CLI をダウンロード
brew install argocd   # macOS
# または
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/download/v2.11.0/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# ログイン
argocd login argocd.youkan.uk \
  --username admin \
  --password 'YourSecurePassword123!'
```

### Step 4: Git リポジトリを Repository として登録

**GitHub リポジトリの場合**

```bash
# 公開リポジトリ
argocd repo add https://github.com/youkan0124/home-infra \
  --type git

# プライベートリポジトリ（SSH）
argocd repo add git@github.com:youkan0124/home-infra \
  --ssh-private-key-path ~/.ssh/id_rsa
```

または UI で:
1. ArgoCD UI → Settings → Repositories
2. CONNECT REPO
3. リポジトリ URL と認証情報を入力

---

## 📦 Application リソース（GitOps）

### 既存: Cloudflare Tunnel Ingress Controller

自動で以下の Application が作成されます：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudflare-tunnel-ingress-controller
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://helm.strrl.dev
    chart: cloudflare-tunnel-ingress-controller
    targetRevision: 0.0.21
    helm:
      valuesObject:
        cloudflare:
          apiToken: "{{ CLOUDFLARE_API_TOKEN }}"
          accountId: "{{ CLOUDFLARE_ACCOUNT_ID }}"
          tunnelName: "{{ CLOUDFLARE_TUNNEL_NAME }}"
  destination:
    server: https://kubernetes.default.svc
    namespace: cloudflare-tunnel-ingress-controller
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
```

### 新規: Application を追加する例

**例: Rancher を GitOps で管理**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: rancher
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://releases.rancher.com/server-charts/latest
    chart: rancher
    targetRevision: "2.12.1"
    helm:
      releaseName: rancher
      values: |
        hostname: rancher.youkan.uk
        replicas: 1
        bootstrapPassword: "{{ RANCHER_PASSWORD }}"
        ingress:
          enabled: true
          ingressClassName: traefik
          tls:
            source: letsEncrypt
            certManagerIssuer: letsencrypt-prod
  destination:
    server: https://kubernetes.default.svc
    namespace: cattle-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

作成方法:
```bash
# ローカルファイルから適用
kubectl apply -f rancher-application.yaml

# または Helm chart から
argocd app create rancher \
  --repo https://releases.rancher.com/server-charts/latest \
  --helm-chart rancher \
  --revision 2.12.1 \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace cattle-system
```

---

## 🔄 同期ポリシー

### 自動同期（推奨）

```yaml
syncPolicy:
  automated:
    prune: true      # 削除されたリソースを自動削除
    selfHeal: true   # 手動変更を自動修正
```

**メリット**: Git の状態が常にクラスタに反映される  
**注意**: 手動でリソースを編集すると上書きされる

### 手動同期

```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
```

同期は手動実行のみ:
```bash
argocd app sync cloudflare-tunnel-ingress-controller
```

---

## 🎮 ArgoCD CLI コマンド

### Application 管理

```bash
# Application 一覧
argocd app list

# Application 詳細表示
argocd app get cloudflare-tunnel-ingress-controller

# Application 状態表示
argocd app wait cloudflare-tunnel-ingress-controller

# Application 同期
argocd app sync cloudflare-tunnel-ingress-controller

# Application 削除
argocd app delete cloudflare-tunnel-ingress-controller

# リソース詳細表示
argocd app resources cloudflare-tunnel-ingress-controller
```

### リポジトリ管理

```bash
# リポジトリ一覧
argocd repo list

# リポジトリ追加
argocd repo add https://github.com/youkan0124/home-infra

# リポジトリ削除
argocd repo rm https://github.com/youkan0124/home-infra
```

### Logs

```bash
# Application ログ表示
argocd app logs cloudflare-tunnel-ingress-controller

# リアルタイム監視
argocd app logs cloudflare-tunnel-ingress-controller -f
```

---

## 📊 状態確認

### UI での確認

1. ArgoCD UI → Applications
2. Application クリック
3. Sync Status（同期状態）を確認
   - **Synced**: Git と同期している ✅
   - **OutOfSync**: 手動で変更されている ⚠️
   - **Unknown**: 同期中または エラー ❌

### CLI での確認

```bash
# 同期状態確認
kubectl get application -n argocd -w

# Application リソース確認
kubectl get application cloudflare-tunnel-ingress-controller -n argocd -o yaml

# 実際のポッド確認
kubectl get pods -n cloudflare-tunnel-ingress
```

---

## 🚨 トラブルシューティング

### Application が OutOfSync

**原因**: クラスタで手動変更がある

**解決**:
```bash
# 自動同期で Git 状態に戻す
argocd app sync cloudflare-tunnel-ingress-controller

# または UI で SYNC ボタンを押す
```

### Application が Failed

```bash
# ログを確認
argocd app logs cloudflare-tunnel-ingress-controller

# または
kubectl describe application cloudflare-tunnel-ingress-controller -n argocd
```

### Helm chart が見つからない

```bash
# Helm リポジトリ確認
helm repo list

# キャッシュをクリア
argocd repo refresh
```

---

## 💾 Git リポジトリ構成（推奨）

```
home-infra/
├── applications/              # Application リソース
│   ├── cloudflare-tunnel-ingress/
│   │   ├── kustomization.yaml
│   │   ├── application.yaml
│   │   └── values.yaml
│   ├── rancher/
│   │   ├── kustomization.yaml
│   │   ├── application.yaml
│   │   └── values.yaml
│   └── app-of-apps.yaml       # 全 Application の親
│
├── helm/                       # Helm charts（カスタム）
├── kubernetes/                 # Kubernetes manifests
│
└── README.md
```

### App of Apps パターン

親 Application で全アプリを管理:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/youkan0124/home-infra
    path: applications
    plugin:
      name: kustomize
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 🔐 セキュリティ

### API Token を隠す（Secret）

Values 内でSecret を参照:

```yaml
helm:
  valuesObject:
    cloudflare:
      apiToken: $cloudflare-token  # secretKeyRef
      accountId: "{{ ACCOUNT_ID }}"
```

Kubernetes Secret として存在:
```bash
kubectl create secret generic cloudflare-token \
  --from-literal=token=YOUR_TOKEN \
  -n cloudflare-tunnel-ingress
```

### RBAC

ArgoCD 用の RBAC ポリシー（本番推奨）:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-server
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argocd-server
subjects:
  - kind: ServiceAccount
    name: argocd-application-controller
    namespace: argocd
  - kind: ServiceAccount
    name: argocd-server
    namespace: argocd
```

---

## 📚 参考リンク

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best-practices/)
- [GitOps Best Practices](https://www.weave.works/blog/gitops-operations-by-pull-request/)

---

**作成日**: 2025-11-21  
**バージョン**: 1.0
