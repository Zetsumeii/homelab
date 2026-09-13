variable "vm_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "node_name" {
  type        = string
  description = "Proxmox target."
}

variable "template_id" {
  type    = number
  default = 9000
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2048
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "storage_pool" {
  type    = string
  default = "VM-pool"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "ip_address" {
  type        = string
  description = "CIDR Static IP, ex: 192.168.1.50/24"
}

variable "gateway" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "ci_user" {
  type    = string
  default = "zetsumei"
}

variable "tags" {
  type    = list(string)
  default = ["terraform", "debian"]
}
