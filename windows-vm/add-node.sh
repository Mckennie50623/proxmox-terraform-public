#!/bin/bash
# Windows VM を1台追加するスクリプト
# 使い方: ./add-node.sh
# ※ main.tf に VM リソースを実装した後、resource名に合わせて grep パターンを修正してください

set -e
cd "$(dirname "$0")"

# 現在のノード数を state から取得
# TODO: 実装後にリソース名に合わせて修正 (例: proxmox_virtual_environment_vm.windows)
CURRENT=$(terraform state list 2>/dev/null | grep -c "proxmox_virtual_environment_vm" || true)
NEW=$((CURRENT + 1))

echo "現在のノード数: $CURRENT → 追加後: $NEW 台"
echo "terraform apply -var=\"node_count=$NEW\" を実行します..."
echo ""

terraform apply -var="node_count=$NEW"
