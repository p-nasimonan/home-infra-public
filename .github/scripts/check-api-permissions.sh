#!/bin/bash

# API Permission Checker Script
# GitHub Actions で実行される各種 API の権限を確認

echo "======================================"
echo "API Permission Check Script"
echo "======================================"
echo ""

# カラー定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# チェック結果の記録
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

check_result() {
  local check_name=$1
  local status=$2
  local message=$3

  case $status in
    "✓")
      echo -e "${GREEN}✓${NC} $check_name: $message"
      ((CHECKS_PASSED++))
      ;;
    "✗")
      echo -e "${RED}✗${NC} $check_name: $message"
      ((CHECKS_FAILED++))
      ;;
    "⚠")
      echo -e "${YELLOW}⚠${NC} $check_name: $message"
      ((CHECKS_WARNING++))
      ;;
  esac
}

echo "1. Checking Proxmox API Permissions..."
echo "---"

# Proxmox API 認証チェック
if [ -z "$TF_VAR_proxmox_token_id" ] || [ -z "$TF_VAR_proxmox_token_secret" ]; then
  check_result "Proxmox Token" "⚠" "Token credentials not found in environment"
else
  PROXMOX_API_URL="${PROXMOX_API_URL:-https://192.168.0.13:8006}"
  PROXMOX_API_TEST=$(curl -s -k -X GET "$PROXMOX_API_URL/api2/json/version" \
    -H "Authorization: PVEAPIToken=$TF_VAR_proxmox_token_id=$TF_VAR_proxmox_token_secret" \
    -o /dev/null -w "%{http_code}")
  
  if [ "$PROXMOX_API_TEST" = "200" ]; then
    check_result "Proxmox API" "✓" "Authentication successful (HTTP $PROXMOX_API_TEST)"
  elif [ "$PROXMOX_API_TEST" = "401" ]; then
    check_result "Proxmox API" "✗" "Authentication failed - Invalid credentials (HTTP 401)"
  else
    check_result "Proxmox API" "⚠" "API response: HTTP $PROXMOX_API_TEST"
  fi
fi

echo ""
echo "2. Checking Terraform Cloud API..."
echo "---"

# Terraform Cloud API 認証チェック
if [ -z "$TF_API_TOKEN" ]; then
  check_result "Terraform Cloud Token" "⚠" "TF_API_TOKEN not set (using local backend if configured)"
else
  TF_CLOUD_API_TEST=$(curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
    https://app.terraform.io/api/v2/account/details \
    -o /dev/null -w "%{http_code}")
  
  if [ "$TF_CLOUD_API_TEST" = "200" ]; then
    check_result "Terraform Cloud API" "✓" "Token is valid (HTTP $TF_CLOUD_API_TEST)"
  elif [ "$TF_CLOUD_API_TEST" = "401" ]; then
    check_result "Terraform Cloud API" "✗" "Authentication failed - Invalid token (HTTP 401)"
  else
    check_result "Terraform Cloud API" "⚠" "API response: HTTP $TF_CLOUD_API_TEST"
  fi
fi

echo ""
echo "======================================"
echo "Summary"
echo "======================================"
echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
echo ""

# 失敗時は終了コード 1 で終了
if [ $CHECKS_FAILED -gt 0 ]; then
  echo -e "${RED}Some API permission checks failed!${NC}"
  exit 1
fi

# 警告がある場合はメッセージを表示
if [ $CHECKS_WARNING -gt 0 ]; then
  echo -e "${YELLOW}Some API checks had warnings - proceeding with caution${NC}"
fi

echo -e "${GREEN}All critical API permission checks passed!${NC}"
exit 0
