# radio-recorder

radiko の番組を定時録音する Kubernetes CronJob。

## ファイル構成

| ファイル | 役割 |
|---------|------|
| `configmap.yaml` | 非機密の環境変数（エリアコードなど） |
| `secret.yaml` | 機密情報（パスワードなど）※ Git 管理外 |
| `pv.yaml` | MiniPC ホストストレージの Kubernetes 登録 |
| `pvc.yaml` | PV への領域予約 |
| `browser.yaml` | 録音済み MP3 をブラウザ再生する nginx + NodePort |
| `cronjob.yaml` | 録音ジョブ本体（番組ごとにコピーして使う） |
| `networkpolicy.yaml` | インバウンド全拒否 / アウトバウンドは DNS + HTTP/HTTPS のみ許可 |

> `secret.yaml` は `.gitignore` により Git 管理外です。手動でバックアップしてください。

## 初回セットアップ

```bash
# 1. 各 YAML の TODO 箇所を埋める
#    - pv.yaml        : ホストパス・ノード名
#    - cronjob.yaml   : イメージ名・スケジュール・番組名
#    - configmap.yaml : 非機密の環境変数
#    - secret.yaml    : 機密情報

# 2. 適用
kubectl apply -f k8s/radio-recorder/configmap.yaml
kubectl apply -f k8s/radio-recorder/secret.yaml
kubectl apply -f k8s/radio-recorder/pv.yaml
kubectl apply -f k8s/radio-recorder/pvc.yaml
kubectl apply -f k8s/radio-recorder/browser.yaml
kubectl apply -f k8s/radio-recorder/networkpolicy.yaml
kubectl apply -f k8s/radio-recorder/cronjob.yaml

# 3. 確認
kubectl get cronjob
kubectl get pvc
```

## 録音済み MP3 をスマホから再生

`browser.yaml` は既存の `radio-data-pvc` を読み取り専用で nginx にマウントし、
`NodePort` の `30080` で公開する。

```bash
kubectl apply -f k8s/radio-recorder/browser.yaml
kubectl get svc radio-browser -n radio-recorder
kubectl get pod -l app=radio-browser -n radio-recorder
```

Android が Tailscale 接続中なら、ブラウザで以下を開く。

```text
http://<example-control-plane の Tailscale IP>:30080/
```

LAN からは以下で開ける。

```text
http://<example-control-plane の LAN IP>:30080/
```

## 番組を追加するとき

`cronjob.yaml` をコピーして番組ごとに編集するだけ。PV/PVC/ConfigMap/Secret は共有して使い回せる。

```bash
# コピーして番組名に合わせてリネーム
cp k8s/radio-recorder/cronjob.yaml k8s/radio-recorder/cronjob-nhk-news.yaml

# 編集箇所（最低限）
#   metadata.name    : radio-recorder-nhk-news
#   spec.schedule    : "0 22 * * 1"  ← 放送時刻に変更
#   env.PROGRAM_NAME : "nhk-news"    ← 番組名に変更

kubectl apply -f k8s/radio-recorder/cronjob-nhk-news.yaml
```

## 手動テスト実行

```bash
# CronJob から即時 Job を作成して実行
kubectl create job --from=cronjob/radio-recorder-example radio-recorder-test

# ログ確認
kubectl logs -l job-name=radio-recorder-test
```

## NetworkPolicy について

NetworkPolicy は CNI プラグインのサポートが必要。k3s デフォルトの Flannel は非対応のため、
有効にするには Calico または Cilium への切り替えが必要。
