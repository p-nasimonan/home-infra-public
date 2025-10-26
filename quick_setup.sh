#!/bin/bash
# Quick setup script for infra-runner LXC
set -e

echo "🚀 Starting setup..."

# Update system
apt-get update && apt-get upgrade -y

# Install basic packages
apt-get install -y curl wget git gnupg software-properties-common ca-certificates unzip

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y terraform

# Install Cloudflared
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared-linux-amd64.deb
rm cloudflared-linux-amd64.deb

# Verify installations
echo ""
echo "✅ Setup complete!"
echo "Terraform: $(terraform version -json | grep -o '"version":"[^"]*' | cut -d'"' -f4)"
echo "Cloudflared: $(cloudflared --version 2>&1 | head -1)"
echo "Git: $(git --version)"
