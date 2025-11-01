# Proxmox ネットワークゾーン（Zone）設定ガイド

## 概要

Proxmox VE の **Zone (Simple)** 機能を使用して、ネットワークセグメントを論理的に分離・管理します。

### 現在の構成

```
┌─────────────────────────────────────────────────────┐
│              Proxmox Infrastructure                │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Zone: default (vmbr0)                              │
│  ├─ Network: 192.168.0.0/24                        │
│  ├─ Gateway: 192.168.0.1                           │
│  ├─ anko (Proxmox Node)                            │
│  ├─ infra-runner (LXC - Terraform/Cloudflared)    │
│  └─ nat-gateway (LXC - Management side)            │
│                                                     │
│  Zone: services (vmbr1)                             │
│  ├─ Network: 10.0.0.0/24                          │
│  ├─ Gateway: 10.0.0.1 (NAT Gateway LXC)           │
│  ├─ coolify (VM - PaaS Platform)                  │
│  ├─ nextcloud (VM - future)                        │
│  └─ homeassistant (VM - future)                    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Zone 作成方法

### 方法1: Proxmox WebUI で手動作成（推奨・簡単）

**手順:**

1. **Proxmox WebUI にログイン**
   ```
   https://<proxmox_host>:8006
   ```

2. **Datacenter → Zones にアクセス**
   ```
   左パネル:
   Datacenter (クリック)
     → Zones (クリック)
   ```

3. **新しい Zone を作成**
   ```
   Create (ボタン)
   
   設定項目:
   - Zone Name: services
   - Description: Services network zone (Coolify, Apps)
   - Type: Simple (ドロップダウンから選択)
   
   Create (ボタン)
   ```

4. **確認**
   ```
   Zones リスト:
   ✓ default (既存)
   ✓ services (新規作成)
   ```

### 方法2: Proxmox CLI で作成

```bash
# Proxmox ホスト (monaka/anko) にSSHで接続
ssh root@192.168.0.8

# Zone 作成コマンド
pvesh create /access/zones -zone services -description "Services network zone (Coolify, Apps)" -type simple

# 確認
pvesh get /access/zones
```

### 方法3: Terraform で自動作成（Advanced）

`network_zones.tf` の `auto_create_zones = true` に変更:

```hcl
locals {
  # Zone 作成フラグ（手動作成の場合は false）
  auto_create_zones = true  # ← false から true に変更
}
```

その後 `terraform apply` で自動実行されます。

## Zone とブリッジのマッピング

### vmbr0 (default zone)

```
Zone: default
├─ Type: Simple
├─ Bridge: vmbr0
├─ Network: 192.168.0.0/24
├─ Gateway: 192.168.0.1
└─ 用途: インフラストラクチャ管理ネットワーク
```

**設定方法:**

Proxmox ホストの `/etc/network/interfaces`:

```bash
auto vmbr0
iface vmbr0 inet static
    address 192.168.0.8
    netmask 255.255.255.0
    gateway 192.168.0.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
```

### vmbr1 (services zone)

```
Zone: services
├─ Type: Simple
├─ Bridge: vmbr1
├─ Network: 10.0.0.0/24
├─ Gateway: 10.0.0.1 (NAT Gateway LXC)
└─ 用途: 隔離サービスネットワーク（Coolify等）
```

**設定方法:**

Proxmox ホストの `/etc/network/interfaces` に追加:

```bash
auto vmbr1
iface vmbr1 inet static
    address 10.0.0.1
    netmask 255.255.255.0
    bridge-ports none
    bridge-stp off
    bridge-fd 0
```

ネットワーク再起動:

```bash
ssh root@192.168.0.8
sudo nano /etc/network/interfaces  # vmbr1 を追加

# 再起動方法1
sudo systemctl restart networking

# または再起動方法2
sudo ifreload -a

# 確認
ip addr show vmbr1
```

## Terraform での参照

### ファイル構成

```
network_zones.tf          ← Zone 定義・参照
├─ locals.zones            Zone設定（name, bridge, network等）
├─ null_resource           Zone自動作成（オプション）
└─ output                  Zone情報の出力

vms.tf                    ← VM/LXC定義
├─ nat_gateway            Zone: default + services
├─ coolify                Zone: services (vmbr1)
└─ comments               Zone マッピング情報
```

### 出力確認

```bash
cd /Users/e245719/Documents/GitHub/home-infra

# Zone設定を確認
terraform output network_zones

# サービスゾーン詳細
terraform output services_zone_config

# NAT Gateway設定
terraform output nat_gateway_config
```

## VM/LXC リソースの Zone 割り当て

### ネットワーク割り当て

**default zone (vmbr0):**

```hcl
resource "proxmox_virtual_environment_container" "infra_runner" {
  # ...
  network_interface {
    name   = "eth0"
    bridge = "vmbr0"  # default zone
  }
}
```

**services zone (vmbr1):**

```hcl
resource "proxmox_virtual_environment_vm" "coolify" {
  # ...
  network_device {
    bridge = "vmbr1"  # services zone
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = "10.0.0.10/24"
        gateway = "10.0.0.1"
      }
    }
  }
}
```

### タグでの Zone 識別

VM/LXC リソースに Zone情報タグを付与:

```hcl
resource "proxmox_virtual_environment_vm" "coolify" {
  # ...
  tags = ["zone:services", "coolify", "paas", "docker", "managed"]
}
```

## トラブルシューティング

### vmbr1 が起動しない

```bash
ssh root@192.168.0.8

# 1. 設定確認
cat /etc/network/interfaces | grep -A 5 vmbr1

# 2. ネットワーク再読み込み
sudo ifreload -a

# 3. ブリッジ確認
ip link show | grep vmbr1

# 4. アドレス確認
ip addr show vmbr1
```

### Coolify VM が 10.0.0.10 に接続できない

```bash
# 1. VM側でIPアドレス確認
ssh root@192.168.0.8
qm guest exec 106 ip addr

# 2. NAT Gateway側でルーティング確認
pct exec <nat-gateway-id> ip route

# 3. Proxmox 側でブリッジ確認
brctl show vmbr1
```

### Zone が WebUI に表示されない

```bash
ssh root@192.168.0.8

# Zone 一覧確認
pvesh get /access/zones

# Zone 作成されていない場合
pvesh create /access/zones -zone services -description "Services network zone" -type simple
```

## 今後の拡張

### 追加 Zone の例

```hcl
# database zone (10.1.0.0/24)
locals {
  zones = {
    default = { ... },
    services = { ... },
    database = {
      name        = "database"
      bridge      = "vmbr2"
      network     = "10.1.0.0/24"
      gateway     = "10.1.0.1"
      description = "Database services network"
    }
  }
}
```

## 参考資料

- [Proxmox VE ドキュメント - Zones](https://pve.proxmox.com/wiki/Zones)
- [bpg/proxmox Terraform Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
