locals {
  # Resolved here, not via module variable defaults: an explicit null passed
  # to a module input does not fall back to its default.
  vm_defaults = {
    cores        = 2
    memory       = 2048
    disk_size    = 20
    balloon      = 0
    started      = true
    os           = "debian"
    storage_pool = var.storage_pool
  }

  os_profiles = {
    debian = {
      template_id         = var.template_id
      disk_interface      = "scsi0"
      vendor_data_file_id = local.cloud_init_file_id
    }
    nixos = {
      template_id         = var.nixos_template_id
      disk_interface      = "virtio0"
      vendor_data_file_id = local.nixos_cloud_init_file_id
    }
  }

  services = {
    nextcloud = {
      vm_id      = 101
      ip_address = "192.168.1.60/24"
      cpu_type   = "host"
      memory     = 6144
    }

    atm10 = {
      vm_id      = 102
      ip_address = "192.168.1.80/24"
      cores      = 8
      cpu_type   = "host"
      memory     = 24576
      disk_size  = 150
    }

    monitoring = {
      vm_id      = 103
      ip_address = "192.168.1.81/24"
      cpu_type   = "host"
    }

    momo = {
      vm_id      = 104
      ip_address = "192.168.1.82/24"
      cpu_type   = "host"
    }

    pwn = {
      vm_id      = 105
      ip_address = "192.168.1.170/24"
      cores      = 4
      cpu_type   = "host"
      memory     = 6144
    }

    imotep = {
      vm_id      = 106
      ip_address = "192.168.1.90/24"
      cpu_type   = "host"
    }

    reflog-registry = {
      vm_id        = 107
      ip_address   = "192.168.1.87/24"
      cpu_type     = "host"
      memory       = 1024
      disk_size    = 100
      storage_pool = "reflog"
      tags         = ["terraform", "debian", "reflog"]
    }

    reflog-preview = {
      vm_id        = 108
      ip_address   = "192.168.1.88/24"
      cores        = 4
      cpu_type     = "host"
      memory       = 4096
      disk_size    = 60
      storage_pool = "reflog"
      tags         = ["terraform", "debian", "reflog"]
    }

    cloudflared = {
      vm_id      = 300
      ip_address = "192.168.1.83/24"
      cpu_type   = "host"
    }
  }

  k8s_spec = {
    os        = "nixos"
    cpu_type  = "host"
    cores     = 4
    memory    = 4096
    disk_size = 30
    tags      = ["terraform", "nixos", "k8s"]
  }

  k8s_hosts = {}

  k8s_nodes = {
    for name, host in local.k8s_hosts :
    name => merge(local.k8s_spec, host)
  }

  vms = {
    for name, vm in merge(local.services, local.k8s_nodes) :
    name => merge(local.vm_defaults, { tags = ["terraform", try(vm.os, local.vm_defaults.os)] }, vm)
  }
}

module "vm" {
  source   = "./modules/vm"
  for_each = local.vms

  vm_name    = each.key
  vm_id      = each.value.vm_id
  ip_address = each.value.ip_address
  cores      = each.value.cores
  cpu_type   = each.value.cpu_type
  memory     = each.value.memory
  balloon    = each.value.balloon
  disk_size  = each.value.disk_size
  started    = each.value.started
  tags       = each.value.tags

  node_name           = var.node_name
  template_id         = local.os_profiles[each.value.os].template_id
  disk_interface      = local.os_profiles[each.value.os].disk_interface
  storage_pool        = each.value.storage_pool
  gateway             = var.gateway
  ssh_public_keys     = var.ssh_public_keys
  vendor_data_file_id = local.os_profiles[each.value.os].vendor_data_file_id

  depends_on = [
    proxmox_virtual_environment_file.cloud_init,
    proxmox_virtual_environment_file.cloud_init_nixos,
  ]
}

output "vms" {
  value = {
    for name, vm in module.vm : name => {
      vm_id      = vm.vm_id
      ip_address = vm.ip_address
    }
  }
}
