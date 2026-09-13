# Without this, Terraform infers the provider from the resource name
# prefix (proxmox_*) and looks for hashicorp/proxmox, which does not
# exist. Child modules must name the source themselves.
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.66"
    }
  }
}
