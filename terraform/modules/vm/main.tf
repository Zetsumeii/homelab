resource "proxmox_virtual_environment_vm" "this" {
  name      = var.vm_name
  vm_id     = var.vm_id
  node_name = var.node_name
  tags      = var.tags

  started       = var.started
  scsi_hardware = var.scsi_hardware
  boot_order    = var.boot_order != null ? var.boot_order : [var.disk_interface]

  dynamic "serial_device" {
    for_each = var.serial_device ? [1] : []
    content {
      device = "socket"
    }
  }

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
    floating  = var.balloon
  }

  disk {
    datastore_id = var.storage_pool
    interface    = var.disk_interface
    size         = var.disk_size
  }

  network_device {
    bridge = var.network_bridge
  }

  initialization {
    vendor_data_file_id = var.vendor_data_file_id

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      username = var.ci_user
      keys     = var.ssh_public_keys
    }
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }
}
