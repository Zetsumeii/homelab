packer {
    required_plugins {
        proxmox = {
            source  = "github.com/hashicorp/proxmox"
            version = ">= 0.1.0"
        }
        ansible = {
            source  = "github.com/hashicorp/ansible"
            version = ">= 0.1.0"
        }
    }
}

variable "proxmox_api_url" {
    type = string
}

variable "proxmox_username" {
    type = string
}

variable "proxmox_password" {
    type = string
    sensitive = true
}

source "proxmox-iso" "baseline" {
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_username}"
    password = "${var.proxmox_password}"
    insecure_skip_tls_verify = true

    ssh_username = "${var.ssh_username}"
    ssh_password = "${var.proxmox_password}"
    ssh_timeout = "20m"

    node = "kyoto"
    vm_id = 5000
    vm_name = "baseline"
    template_description = "Baseline template for Packer"

    boot_iso {
      type = "scsi"
      iso_file = "local-lvm:iso/debian-12.5.0-amd64-netinst.iso"
      unmount = true
      iso_checksum = "sha512:33c08e56c83d13007e4a5511b9bf2c4926c4aa12fd5dd56d493c0653aecbab380988c5bf1671dbaea75c582827797d98c4a611f7fb2b131fbde2c677d5258ec9"
    }

    disks {
        type = "scsi"
        disk_size = "8G"
        storage_pool = "local-lvm"
    }

    sockets = 1
    cores = 2

    memory = 2048
    ballooning_minimum = 512

    qemu_agent = true

    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
    }

    cloud_init = true
    cloud_init_storage_pool = "local-lvm"
    http_directory = "config"
}

build {

    name = "baseline"
    sources = ["source.proxmox-iso.baseline"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }
}