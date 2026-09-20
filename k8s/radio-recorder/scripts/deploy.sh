#!/bin/bash
# radio-recorder の k8s マニフェストをすべて適用する。
# 実行場所: k3s ノード上（proxmox_terraform リポジトリのルート、または k8s/radio-recorder/）
set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Namespace / Storage を適用..."
kubectl apply -f "${DIR}/namespace.yaml"
kubectl apply -f "${DIR}/pv.yaml"
kubectl apply -f "${DIR}/pvc.yaml"
kubectl apply -f "${DIR}/networkpolicy.yaml"
kubectl apply -f "${DIR}/browser.yaml"

echo ""
echo "==> シークレットを適用..."
if [ ! -f "${DIR}/secret.yaml" ] || grep -q '<' "${DIR}/secret.yaml"; then
  echo "ERROR: ${DIR}/secret.yaml に値が未記入です。テンプレートを確認してください。"
  exit 1
fi
kubectl apply -f "${DIR}/secret.yaml"

if [ ! -f "${DIR}/google-credentials.yaml" ] || grep -q '<' "${DIR}/google-credentials.yaml"; then
  echo "ERROR: ${DIR}/google-credentials.yaml に credentials.json が未記入です。"
  exit 1
fi
kubectl apply -f "${DIR}/google-credentials.yaml"

echo ""
echo "==> 番組 CronJob を適用..."
for program_dir in "${DIR}/programs"/*/; do
  echo "    ${program_dir}"
  kubectl apply -f "${program_dir}"
done

echo ""
echo "==> 完了。CronJob 一覧:"
kubectl get cronjobs -n radio-recorder
