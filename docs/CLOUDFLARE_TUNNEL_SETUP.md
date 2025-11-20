# Cloudflare Tunnel Ingress Controller セットアップガイド

ゼロトラスト環境で Kubernetes cluster を Cloudflare Tunnel 経由で公開します。

## 🎯 概要

**構成**
```
【ユーザー】
     ↓
【Cloudflare DNS】 rancher.youkan.uk
     ↓
【Cloudflare Tunnel】（双方向通信）
     ↓
【Cloudflare Tunnel Ingress Controller】（K3s）
     ↓
【Rancher・その他アプリ】（内部ネットワークのみ）
```

**メリット**
- ✅ 外部ネットワークにポート開放不要
- ✅ 内部ネットワークは完全隔離（ゼロトラスト）
- ✅ Kubernetes Ingress manifest で routing 管理
- ✅ Cloudflare の DDoS 保護・WAF 統合

---

## 📋 前提条件

1. ✅ K3s cluster が起動している（3 ノード HA）
2. ✅ Rancher がインストール完了
3. ✅ Cloudflare account がある（DNS 管理）
4. ✅ `cloudflared` CLI がインストールされている

---

## 🔧 セットアップ手順

### Step 1: Cloudflare Tunnel を作成

```bash
# ログイン
cloudflared tunnel login

# トンネルを作成
cloudflared tunnel create k3s-rancher

# 確認
cloudflared tunnel list
```

出力例：
```
ID                                   Name           Account     Created
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx k3s-rancher    youkan.uk   2024-12-20
```

### Step 2: Tunnel Credentials を取得

```bash
# Token を出力（後で Ansible に渡す）
cloudflared tunnel token k3s-rancher
```

出力例：
```
eyJhIjoixxxxxxxxxxxxxxx...
```

### Step 3: Tunnel Account ID を確認

Cloudflare ダッシュボード → Account ID
```
例: 1a2b3c4d5e6f7g8h9i0j
```

### Step 4: DNS レコードを設定

```bash
# または Cloudflare ダッシュボードで設定:
# Type: CNAME
# Name: rancher
# Content: <tunnel-id>.cfargotunnel.com
# Proxy: プロキシ済み ✓

# CLI:
cloudflared tunnel route dns k3s-rancher rancher.youkan.uk
```

確認:
```bash
cloudflared tunnel route list k3s-rancher
```

### Step 5: Ansible でデプロイ

```bash
# playbook-cloudflare-tunnel-ingress.yml を実行
ansible-playbook \
  -i ansible/inventory.yml \
  ansible/playbook-k3s-setup.yml \
  -e "cf_account_id=<YOUR_ACCOUNT_ID>" \
  -e "cf_tunnel_token=<YOUR_TUNNEL_TOKEN>"
```

例:
```bash
ansible-playbook \
  -i ansible/inventory.yml \
  ansible/playbook-k3s-setup.yml \
  -e "cf_account_id=1a2b3c4d5e6f7g8h9i0j" \
  -e "cf_tunnel_token=eyJhIjoixxxxxxxxxxxxxxx..."
```

### Step 6: インストール確認

```bash
# Namespace とポッドを確認
kubectl get pods -n cloudflare-tunnel-ingress

# IngressClass を確認
kubectl get ingressclass
```

出力例:
```
NAME                   CONTROLLER                                        AGE
cloudflare             kubernetes.io/ingress.class                       2m
traefik (default)      traefik.io/ingress.controller                     10m
```

---

## 🚀 Rancher を Cloudflare Tunnel 経由で公開

### Ingress リソースを作成（Rancher 向け）

すでに自動設定されていますが、確認用のマニフェスト:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rancher-tunnel
  namespace: cattle-system
  annotations:
    # Cloudflare Tunnel Ingress を指定
    cert.issuer: letsencrypt-prod
spec:
  ingressClassName: cloudflare
  rules:
    - host: rancher.youkan.uk
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: rancher
                port:
                  number: 80
  tls:
    - hosts:
        - rancher.youkan.uk
      secretName: rancher-tls
```

### 適用

```bash
kubectl apply -f rancher-tunnel-ingress.yaml
```

---

## ✅ 動作確認

### 1. Ingress 状態確認

```bash
kubectl get ingress -n cattle-system -w
```

### 2. Tunnel 状態確認

```bash
# Tunnel の接続状態を確認
cloudflared tunnel status k3s-rancher
```

### 3. ブラウザで接続

```
https://rancher.youkan.uk
```

✅ Rancher ログイン画面が表示されたら成功！

---

## 📱 その他のアプリケーション公開

### 例: 別のアプリを公開する場合

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-tunnel
  namespace: myapp
spec:
  ingressClassName: cloudflare
  rules:
    - host: myapp.youkan.uk
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp-service
                port:
                  number: 8080
```

DNS 登録:
```bash
cloudflared tunnel route dns k3s-rancher myapp.youkan.uk
```

---

## 🔒 セキュリティ設定（推奨）

### Cloudflare WAF ルール（オプション）

1. Cloudflare ダッシュボード → Security → WAF
2. Managed Ruleset を有効化
3. Rate Limiting ルールを追加

### 認証ルール（オプション）

```bash
# Cloudflare Access で認証を追加（有料機能）
cloudflared tunnel route oauth k3s-rancher rancher.youkan.uk
```

---

## 🐛 トラブルシューティング

### Ingress が EXTERNAL-IP を取得できない

```bash
kubectl describe ingress rancher-tunnel -n cattle-system
```

**原因**: Cloudflare Tunnel Ingress Controller が起動していない

**解決**:
```bash
kubectl get pods -n cloudflare-tunnel-ingress
kubectl logs -n cloudflare-tunnel-ingress deployment/cloudflare-tunnel-ingress
```

### Tunnel 接続がタイムアウト

```bash
cloudflared tunnel run k3s-rancher --loglevel debug
```

**原因**: 
- Tunnel Token が無効
- Account ID が不正
- DNS レコードが未設定

### DNS 解決に失敗

```bash
nslookup rancher.youkan.uk
dig rancher.youkan.uk @1.1.1.1
```

---

## 📚 参考リンク

- [Cloudflare Tunnel Ingress Controller](https://github.com/cloudflare/cloudflare-operator)
- [cloudflared CLI ドキュメント](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

---

## 🎓 Traefik vs Cloudflare Tunnel Ingress

| 項目 | Traefik | Cloudflare Tunnel |
|------|---------|-------------------|
| K3s との統合 | 🟢 ネイティブ | 🟡 Ingress Controller |
| ポート開放 | 必要 | 不要 |
| セキュリティ | VPN/内部ネット | ゼロトラスト |
| 用途 | 内部 routing | 外部公開 |

**推奨構成**
- ✅ **Traefik**: 内部 cluster routing（K3s デフォルト、有効化推奨）
- ✅ **Cloudflare Tunnel Ingress**: 外部公開（ゼロトラスト）

---

**作成日**: 2024-12-20  
**更新日**: 2024-12-20  
**バージョン**: 1.0
