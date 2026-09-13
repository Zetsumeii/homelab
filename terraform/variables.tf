variable "proxmox_endpoint" {
  type        = string
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  type        = bool
  default     = false
}

variable "node_name" {
  type        = string
}

variable "template_id" {
  type        = number
  default     = 9000
}

variable "storage_pool" {
  type        = string
  default     = "VM-pool"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "gateway" {
  type        = string
}

variable "ssh_public_key" {
  type        = string
}
