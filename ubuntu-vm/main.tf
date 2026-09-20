terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.95.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.pm_api_url
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure = true
}

resource "proxmox_virtual_environment_vm" "k3s" {
  name      = "k3s"
  vm_id     = 200
  node_name = var.target_node

  # テンプレートからクローン
  clone {
    vm_id = var.template_vm_id
  }

  # QEMU Agentを有効化
  agent {
    enabled = true
  }

  # CPU設定
  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

  # メモリ設定（MB単位）
  memory {
    dedicated = 2048
  }

  # ディスク設定
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 10
  }

  # ネットワーク設定
  network_device {
    bridge = "vmbr0"
  }

  # Cloud-Init設定
  initialization {
    ip_config {
      ipv4 {
        address = var.vm_ipv4_cidr
        gateway = var.network_gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(file(var.ssh_key_file))]
    }
  }

  # VM作成後に、SSHでログインしてコマンドを実行する設定
  provisioner "remote-exec" {
    # 接続設定
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_file)
      host        = self.ipv4_addresses[1][0]
    }

    inline = [
      "curl -sfL https://get.k3s.io | sh -"
    ]
  }
}
