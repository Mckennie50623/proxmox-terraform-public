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
  sensitive   = true
}

variable "target_node" {
  description = "Proxmox Node Name"
  type        = string
  # Required: the node name in your own environment.
}

variable "node_count" {
  description = "Number of Windows VMs to create"
  type        = number
  default     = 1
}

variable "template_vm_id" {
  description = "VM ID of the Windows template to clone"
  type        = number
}
