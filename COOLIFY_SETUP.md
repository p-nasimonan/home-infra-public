# Coolify VM セットアップ手順

## 事前準備：cloud-init設定ファイルの配置

Terraformを実行する前に、Proxmoxサーバーにcloud-init設定ファイルを配置する必要があります。

### 手順

1. **Proxmoxノード（monaka）にSSH接続**
   ```bash
   ssh root@<monaka-ip-address>
   ```

2. **snippetsディレクトリを作成**（存在しない場合）
   ```bash
   mkdir -p /var/lib/vz/snippets
   ```

3. **cloud-init設定ファイルをコピー**
   
   ローカルから:
   ```bash
   scp cloud-init/coolify-init.yaml root@<monaka-ip-address>:/var/lib/vz/snippets/
   ```

4. **権限設定**
   ```bash
   chmod 644 /var/lib/vz/snippets/coolify-init.yaml
   ```

5. **Terraform apply実行**
   
   GitHub Actionsから「apply」を実行するか、ローカルで:
   ```bash
   terraform apply
   ```

## VM作成後

VMが作成されたら、数分待ってからSSH接続してCoolifyのインストール状況を確認してください。

```bash
# VMのIPアドレスを確認
terraform output coolify_info

# SSH接続
ssh ubuntu@<coolify-vm-ip>
# パスワード: Coolify2024!

# Coolifyインストール状況確認
docker ps
cat /var/log/coolify-install.log
```

Coolifyダッシュボードへのアクセス:
```
http://<coolify-vm-ip>:8000
```
