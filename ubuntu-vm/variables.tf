variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
}

variable "pm_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true # ログに出力されないようにする
}

variable "ssh_key_file" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "target_node" {
  description = "Proxmox Node Name"
  type        = string
  # Required: the node name in your own environment.
}

variable "template_vm_id" {
  description = "VM ID of the template to clone"
  type        = number
  default     = 9000
}

variable "ssh_private_key_file" {
  description = "Path to the SSH private key for connection"
  type        = string
  default     = "~/.ssh/id_ed25519" # 秘密鍵（.pubがつかない方！）
}

variable "vm_ipv4_cidr" {
  description = "VM IPv4 address with CIDR; set explicitly for your environment"
  type        = string
}

variable "network_gateway" {
  description = "Network Gateway IP"
  type        = string
  # No deployment-specific default: supply your own gateway.
}
