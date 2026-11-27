resource "tailscale_tailnet_key" "vm" {
  count = var.tailscale_enabled ? 1 : 0

  reusable            = true
  ephemeral           = false
  preauthorized       = true
  tags                = var.tailscale_tags
  expiry              = var.tailscale_key_expiry
  description         = "terraform homelab VM enrolment"
  recreate_if_invalid = "always"
}

locals {
  tailscale_template_vars = {
    tailscale_enabled  = var.tailscale_enabled
    tailscale_auth_key = var.tailscale_enabled ? tailscale_tailnet_key.vm[0].key : ""
    tailscale_up_flags = length(var.tailscale_up_flags) > 0 ? " ${join(" ", var.tailscale_up_flags)}" : ""
  }

  # Built from known parts, not the file resource's .id: an unknown id at plan
  # time would force a replacement of every VM. Changing a file name does too.
  cloud_init_file_name       = "qemu-guest-agent.yml"
  cloud_init_file_id         = "${var.snippet_datastore}:snippets/${local.cloud_init_file_name}"
  nixos_cloud_init_file_name = "nixos-vendor.yml"
  nixos_cloud_init_file_id   = "${var.snippet_datastore}:snippets/${local.nixos_cloud_init_file_name}"
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore
  node_name    = var.node_name
  overwrite    = true

  source_raw {
    data      = templatefile("${path.module}/snippets/cloud-init.yaml.tftpl", local.tailscale_template_vars)
    file_name = local.cloud_init_file_name
  }

  lifecycle {
    postcondition {
      condition     = self.id == local.cloud_init_file_id
      error_message = "Snippet id ${self.id} does not match ${local.cloud_init_file_id}."
    }
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_nixos" {
  content_type = "snippets"
  datastore_id = var.snippet_datastore
  node_name    = var.node_name
  overwrite    = true

  source_raw {
    data      = templatefile("${path.module}/snippets/cloud-init-nixos.yaml.tftpl", local.tailscale_template_vars)
    file_name = local.nixos_cloud_init_file_name
  }

  lifecycle {
    postcondition {
      condition     = self.id == local.nixos_cloud_init_file_id
      error_message = "Snippet id ${self.id} does not match ${local.nixos_cloud_init_file_id}."
    }
  }
}
