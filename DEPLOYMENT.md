# ✅ Proxmox コンソール公開完了

## 🎉 完了したこと

Proxmox VE コンソール (`https://192.168.0.13:8006`) を Cloudflare Tunnel 経由で公開しました。

### 作成されたリソース

1. **Cloudflare Tunnel**: `home-tunnel`
   - Tunnel ID: `494fcde0-e9e3-435b-8200-84b21823fb93`
   
2. **DNSレコード**: `pve.youkan.uk` (CNAME → tunnel)

3. **Ingress ルール**: 
   - `https://pve.youkan.uk` → `https://192.168.0.13:8006`

## 🚀 次のステップ: Cloudflared を起動

### ローカルPCで実行する場合

以下のコマンドでトンネルを起動してください：

```powershell
cloudflared tunnel run --token eyJhIjoiYWNjMDk1ZGVkODZkMDlhNDBmMjA3YjQzN2FlNWYyZGUiLCJ0IjoiNDk0ZmNkZTAtZTllMy00MzViLTgyMDAtODRiMjE4MjNmYjkzIiwicyI6IlhnWXhtOTRQRE5rdWYrbEVOam1yNUJGODJmcFIzVHdwalVyQ0lSWEJaT3M9In0=
```

### バックグラウンドで実行する場合

```powershell
# PowerShellでバックグラウンド起動
Start-Process cloudflared -ArgumentList "tunnel","run","--token","eyJhIjoiYWNjMDk1ZGVkODZkMDlhNDBmMjA3YjQzN2FlNWYyZGUiLCJ0IjoiNDk0ZmNkZTAtZTllMy00MzViLTgyMDAtODRiMjE4MjNmYjkzIiwicyI6IlhnWXhtOTRQRE5rdWYrbEVOam1yNUJGODJmcFIzVHdwalVyQ0lSWEJaT3M9In0=" -NoNewWindow
```

### Windowsサービスとして登録する場合

```powershell
# サービスとしてインストール
cloudflared service install eyJhIjoiYWNjMDk1ZGVkODZkMDlhNDBmMjA3YjQzN2FlNWYyZGUiLCJ0IjoiNDk0ZmNkZTAtZTllMy00MzViLTgyMDAtODRiMjE4MjNmYjkzIiwicyI6IlhnWXhtOTRQRE5rdWYrbEVOam1yNUJGODJmcFIzVHdwalVyQ0lSWEJaT3M9In0=

# サービス開始
Start-Service cloudflared
```

## 🌐 アクセス方法

Cloudflared を起動したら、以下のURLにアクセスできます：

**Proxmox VE Console**: https://pve.youkan.uk

## 🔒 セキュリティ注意事項

### 推奨: Cloudflare Access で認証を追加

現在は誰でもアクセスできる状態です。本番運用では Cloudflare Access で認証を追加することを強く推奨します：

1. Cloudflare ダッシュボード → Zero Trust → Access → Applications
2. "Add an application" をクリック
3. Self-hosted を選択
4. Application domain: `pve.youkan.uk`
5. Policy を設定（例: Google アカウントで認証）

### 推奨: TLS検証設定

Proxmox が自己署名証明書を使っている場合、Tunnel 設定に以下を追加：

```hcl
# tunnel.tf の ingress_rule に追加
origin_server_name = "192.168.0.13"
no_tls_verify      = true  # 自己署名証明書の場合のみ
```

## 📊 動作確認

```powershell
# DNS確認
nslookup pve.youkan.uk

# アクセステスト
curl https://pve.youkan.uk
```

## 🎯 次に公開できるサービス例

`terraform.tfvars` に追加して、同じ手順で公開できます：

```hcl
services = {
  "proxmox" = {
    subdomain   = "pve"
    local_url   = "https://192.168.0.13:8006"
    description = "Proxmox VE Console"
  }
  "homeassistant" = {
    subdomain   = "home"
    local_url   = "http://192.168.0.102:8123"
    description = "Home Assistant"
  }
  "nextcloud" = {
    subdomain   = "cloud"
    local_url   = "http://192.168.0.101:80"
    description = "Nextcloud"
  }
}
```

## 📞 トラブルシューティング

### Cloudflared が接続できない

```powershell
# 詳細ログで起動
cloudflared tunnel --loglevel debug run --token <token>
```

### "connection refused" エラー

1. Proxmox が起動しているか確認
2. `192.168.0.13:8006` にローカルからアクセスできるか確認
3. Cloudflared を実行している環境から `curl -k https://192.168.0.13:8006` でテスト

### DNS が反映されない

- 最大48時間かかることがありますが、通常は数分で反映されます
- `nslookup pve.youkan.uk 1.1.1.1` で Cloudflare DNS に直接問い合わせ

---

**おめでとうございます！🎉**  
Proxmox コンソールがインターネット経由で安全にアクセスできるようになりました。
