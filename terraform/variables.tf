variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "proxmox_insecure" {
  type    = bool
  default = false
}

variable "node_name" {
  type = string
}

variable "template_id" {
  type        = number
  default     = 9000
  description = "Debian cloud-init template, used by VMs with os = \"debian\"."
}

variable "nixos_template_id" {
  type        = number
  default     = 9001
  description = "NixOS template built from nixos/template, used by VMs with os = \"nixos\"."
}

variable "storage_pool" {
  type    = string
  default = "VM-pool"
}

variable "gateway" {
  type = string
}

variable "ssh_public_keys" {
  type = list(string)
}

variable "tailscale_enabled" {
  type        = bool
  default     = true
  description = "Install and enrol Tailscale via cloud-init on newly created VMs."
}

variable "tailscale_tailnet" {
  type        = string
  default     = "-"
  description = "Tailnet name. \"-\" means the default tailnet of the authenticated account."
}

variable "tailscale_oauth_client_id" {
  type    = string
  default = ""
}

variable "tailscale_oauth_client_secret" {
  type      = string
  sensitive = true
  default   = ""
}

variable "tailscale_tags" {
  type        = list(string)
  default     = ["tag:homelab"]
  description = "Tags applied to enrolled machines. Each needs a tagOwner in the tailnet ACL."
}

variable "tailscale_key_expiry" {
  type        = number
  default     = 7776000
  description = "Auth key lifetime in seconds. Default 90 days, the Tailscale maximum."
}

variable "tailscale_up_flags" {
  type        = list(string)
  default     = []
  description = "Extra flags for `tailscale up`, e.g. [\"--ssh\", \"--accept-routes\"]."
}

variable "proxmox_ssh_username" {
  type    = string
  default = "root"
}

variable "proxmox_ssh_private_key_file" {
  type        = string
  default     = "~/.ssh/id_ed25519"
  description = "Key authorised on the Proxmox node. Snippets upload over SSH, not the API."
}

variable "snippet_datastore" {
  type    = string
  default = "local"
}
