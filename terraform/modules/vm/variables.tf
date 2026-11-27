variable "vm_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "node_name" {
  type = string
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

variable "ssh_public_keys" {
  type = list(string)
}

variable "ci_user" {
  type    = string
  default = "zetsumei"
}

variable "vendor_data_file_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = list(string)
  default = ["terraform", "debian"]
}

variable "scsi_hardware" {
  type    = string
  default = "virtio-scsi-single"
}

variable "disk_interface" {
  type        = string
  default     = "scsi0"
  description = "Bus of the template's root disk; any other bus adds a new empty disk."
}

variable "boot_order" {
  type        = list(string)
  default     = null
  description = "Defaults to booting from disk_interface."
}

variable "serial_device" {
  type        = bool
  default     = true
  description = "Cloud images boot with console=ttyS0 and panic without one."
}

variable "started" {
  type    = bool
  default = true
}

variable "cpu_type" {
  type    = string
  default = "qemu64"
}

variable "balloon" {
  type        = number
  default     = 0
  description = "Ballooning floor in MB; 0 disables ballooning."
}
