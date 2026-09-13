packer {
    required_plugins {
        proxmox = {
            source  = "github.com/hashicorp/proxmox"
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

variable "ssh_username" {
    type = string
}

variable "proxmox_insecure" {
    type = bool
    description = "Skip Proxmox API TLS verification. Set true only for a self-signed node cert."
    default = false
}

variable "http_bind_address" {
    type = string
    description = "Interface the autoinstall HTTP server binds to. Must be reachable by the Proxmox node; prefer the LAN address over 0.0.0.0."
    default = "0.0.0.0"
}

variable "ssh_private_key_file" {
    type = string
    description = "Path to the private key matching the pubkey injected by config/user-data."
}

source "proxmox-iso" "baseline" {
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_username}"
    password = "${var.proxmox_password}"
    insecure_skip_tls_verify = "${var.proxmox_insecure}"

    ssh_username = "${var.ssh_username}"
    ssh_private_key_file = "${var.ssh_private_key_file}"
    ssh_timeout = "20m"

    node = "kyoto"
    vm_id = 5000
    vm_name = "baseline"
    template_description = "Baseline template for Packer"

    boot_iso {
      type = "scsi"
      iso_file = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
      unmount = true
      iso_checksum = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
    }

    disks {
        type = "scsi"
        disk_size = "8G"
        storage_pool = "VM-pool"
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
    cloud_init_storage_pool = "VM-pool"
    http_directory = "config"
    http_bind_address = "${var.http_bind_address}"
    http_port_min = 8802
    http_port_max = 8802

    boot_command = [
        "<esc><wait>",
        "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"",
        "<enter><wait>",
        "initrd /casper/initrd",
        "<enter><wait>",
        "boot",
        "<enter>"
    ]
    boot_wait = "5s"
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
