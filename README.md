# Proxmox / k3s ホームラボ構成

Proxmox VE 上の Ubuntu VM を Terraform で作成し、k3s と Kubernetes マニフェストを使ってサービスを配置する個人用ホームラボのリポジトリです。完成済みの汎用モジュールではなく、構築コードと設計資料をまとめています。

## 見どころと実装範囲

| 対象 | 状態・読む場所 |
|---|---|
| Ubuntu VM | [Terraform](ubuntu-vm/main.tf)：既存テンプレートのクローン、CPU・メモリ・ディスク・Cloud-Init・SSHによるk3s導入 |
| Windows VM | [プロバイダー設定のみ](windows-vm/main.tf)。VMリソースは未実装 |
| Obsidian同期 | [Kubernetesマニフェスト](k8s/obsidian-sync/)と[構成資料](obsidian-sync-architecture.md) |
| ラジオ録音 | [CronJob・ストレージ・NetworkPolicy](k8s/radio-recorder/)と[手順](k8s/radio-recorder/README.md) |
| 全体構成 | [設計資料](architecture.md)。計画・運用構成を含み、すべてがTerraformで実装済みという意味ではありません |

**現行コードの制約:** Ubuntu側は固定VM IDの単一VMを作成します。`curl -sfL https://get.k3s.io | sh -` による導入で、既存クラスターのワーカーノードへの自動参加は実装されていません。Windows VM・汎用的な複数ノード展開・LXC作成も未実装です。

## 構成

```text
ubuntu-vm/        Ubuntu VMとk3s導入
windows-vm/       Windows VM用の設定雛形（未実装）
k8s/
  obsidian-sync/ CouchDBによる同期構成
  radio-recorder/録音用CronJob等
  infrastructure/共通インフラ配置先（プレースホルダー）
```

## ローカルで設定を確認する

前提としてTerraform、Proxmox VE、クローン可能なUbuntuテンプレート、必要な権限に限定したAPIトークン、SSH鍵を用意します。各Terraformディレクトリは独立しています。

```bash
cd ubuntu-vm
cp terraform.tfvars.example terraform.tfvars
# YOUR_*等のプレースホルダーを実際の値に置き換える
# VM ID、IP、ストレージ、ブリッジ、SSH接続先もmain.tfと照合する
terraform init
terraform validate
terraform plan
```

`terraform plan` はProxmox APIへアクセスする可能性があります。`apply` はリソースを変更するので、差分と対象環境を確認した後にのみ実行してください。Windows側の `apply` ではVMは作成されません。

Kubernetesマニフェストも環境依存です。Secret、ストレージ、Ingress、名前空間などを準備し、内容を確認してから個別に適用してください。一括適用だけで全構成が完成することは保証していません。

## セキュリティ・公開時の注意

- 現行のProxmoxプロバイダー設定は `insecure = true` です。TLS証明書検証が無効なため、そのまま本番用途へ転用しないでください。信頼できる証明書を用意し、検証を有効化する必要があります。
- k3sの導入スクリプトはリモートから取得して実行します。バージョン固定・取得元の検証は今後の改善点です。
- Terraform state / planには秘密情報が含まれ得ます。`sensitive = true` はstateの暗号化を意味しません。安全な保管先とアクセス制御が必要です。
- APIトークン、SSH秘密鍵、kubeconfig、Kubernetes Secretはコミットしないでください。`.gitignore` はすでに追跡されたファイルや過去履歴には効きません。
- 現行ファイルのドメイン・IP・ノード名は公開用サンプルへ置換済みです。`example.com` / `192.0.2.0/24` は例示専用です。旧Git履歴には元の情報が残るため、この既存リポジトリをそのままpublic化しないでください。
- Ubuntuのネットワーク入力は `vm_ipv4_cidr` と `network_gateway` の必須指定に変更しました。旧 `ip_address_start` / `network_cidr` は使用しません。`target_node` も明示指定してください。
- 録音用サンプルCronJobは `suspend: true` です。実行を許可するまで解除しないでください。
- 録音データや外部サービスの利用には、サービス規約・権利者の条件が別途適用されます。

[公開サンプルと非公開運用の分離](OPERATIONS.md)を参照してください。本リポジトリは設計・実装のサンプルであり、実環境の状態や安全性を保証するものではありません。
