# 自宅サーバ システム構成図

> 公開用サンプル構成です。ドメイン・IP・ノード名は実環境と対応しない例示値へ置換しています。`example.com` と `192.0.2.0/24` は説明用であり、そのまま接続・デプロイできません。構成図は設計例を含み、実環境の状態・安全性を保証しません。

## 全体構成

```mermaid
graph TB
    subgraph Internet["インターネット"]
        WAN["WAN"]
    end

    subgraph Home["自宅ネットワーク 192.0.2.0/24"]
        GW["ホームルーター\n192.0.2.1"]

        subgraph PVE["物理サーバ : Proxmox VE (pve)\nvmbr0 ブリッジ接続"]

            subgraph K3S["k3s クラスター"]
                subgraph Master["Ubuntu VM : example-control-plane\n192.0.2.50"]
                    K3S_SERVER["k3s server\n(Control Plane)"]
                end

                subgraph Workers["Ubuntu VM : example-worker-1〜N\n(VM ID: 200+, IP: 192.0.2.51+)\n2コア / 2GB RAM / 10GB disk"]
                    K3S_AGENT["k3s agent\n(Worker Node)"]
                    subgraph Pods["Kubernetes Pods"]
                        POD1["Pod"]
                        POD2["Pod"]
                        PODN["..."]
                    end
                end
            end

            subgraph WinVM["Windows VM (TODO)\n未実装"]
                WIN["Windows"]
            end
        end

        subgraph IaC["管理 (Infrastructure as Code)"]
            TF["Terraform\nbpg/proxmox provider"]
        end
    end

    WAN --> GW
    GW --> PVE
    TF -- "Proxmox API\n(HTTPS)" --> PVE
    K3S_SERVER -- "ノード参加\nK3S_TOKEN" --> K3S_AGENT

```

## レイヤー別構成

```mermaid
graph BT
    subgraph L1["L1 : 物理ハードウェア"]
        HW["物理サーバ"]
    end

    subgraph L2["L2 : ハイパーバイザー"]
        PROXMOX["Proxmox VE\n(KVM + LXC)"]
    end

    subgraph L3["L3 : 仮想化リソース"]
        UBVM["Ubuntu VM × N\nexample-worker-1〜N\nVM ID: 200+\nIP: 192.0.2.51+"]
        WINVM2["Windows VM\n(TODO)"]
    end

    subgraph L4["L4 : コンテナオーケストレーション"]
        K3SCLUSTER["k3s クラスター\n(1 master + N workers)"]
    end

    subgraph L5["L5 : アプリケーション"]
        APPS["Kubernetes Pods\n(各種サービス)"]
    end

    subgraph MGMT["管理レイヤー"]
        TERRAFORM["Terraform\nVM / LXC の作成・管理"]
    end

    HW --> PROXMOX
    PROXMOX --> UBVM
    PROXMOX --> WINVM2
    UBVM --> K3SCLUSTER
    K3SCLUSTER --> APPS
    TERRAFORM -.->|Proxmox API| PROXMOX
```

## リソース一覧

| 種別 | 名前 | VM ID | IP アドレス | スペック | 用途 |
|------|------|-------|------------|---------|------|
| Ubuntu VM | example-control-plane | - | 192.0.2.50 | - | k3s Control Plane |
| Ubuntu VM | example-worker-1〜N | 200+ | 192.0.2.51+ | 2コア / 2GB / 10GB | k3s Worker |
| Windows VM | (未定) | - | - | - | TODO |

## ネットワーク構成

| 項目 | 値 |
|------|----|
| セグメント | 192.0.2.0/24 |
| ゲートウェイ | 192.0.2.1 |
| Proxmox ブリッジ | vmbr0 |
| k3s Master | 192.0.2.50 |
| k3s Workers | 192.0.2.51〜 |

## IaC 管理構成

```
proxmox_terraform/
├── ubuntu-vm/   # k3s Worker ノード用 Ubuntu VM (Terraform)
└── windows-vm/  # Windows VM (TODO・main.tf 未実装)
```

- **Terraform プロバイダー**: `bpg/proxmox ~> 0.95.0`
- **プロビジョニング**: Cloud-Init (Ubuntu VM) / SSH鍵認証
- **k3s インストール**: `remote-exec` で導入。既存クラスターへのワーカー参加は未実装。
