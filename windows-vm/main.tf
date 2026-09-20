# Windows VM 用 Terraform 設定
# TODO: proxmox_virtual_environment_vm リソースを実装（Windows テンプレート用）

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.95.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pm_api_url
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure  = true
}

# プレースホルダー: Windows VM の実装を追加してください
# resource "proxmox_virtual_environment_vm" "windows" {
#   ...
# }
