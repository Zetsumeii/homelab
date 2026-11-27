# Terraform

Creates the VMs on the Proxmox node `kyoto` by cloning a template: Debian 13
(9000) or NixOS (9001, built from `../nixos/template`). New VMs install the
guest agent and join the tailnet at first boot through a cloud-init snippet.

```
main.tf         the VMs: one entry per machine
tailscale.tf    tailnet auth key and the cloud-init snippets
variables.tf    inputs, set in terraform.tfvars (gitignored: API token, keys)
modules/vm/     the VM resource itself
snippets/       cloud-init vendor data templates
```

```sh
terraform init        # once, and after changing a module source
terraform plan        # always read it before applying
terraform apply
```

## Adding a VM

Add an entry to `local.services` in `main.tf`:

```hcl
myservice = {
  vm_id      = 109                 # unique on the node
  ip_address = "192.168.1.89/24"   # static, outside the router's DHCP range
  cpu_type   = "host"              # required
  cores      = 4                   # optional, see defaults below
  memory     = 8192
  disk_size  = 40
}
```

| Field | Default | Notes |
|---|---|---|
| `cores` | 2 | |
| `memory` | 2048 | MB |
| `disk_size` | 20 | GB, can only grow |
| `balloon` | 0 | 0 disables ballooning; keep it for JVM workloads like atm10 |
| `started` | true | |
| `os` | `"debian"` | `"nixos"` clones 9001 (disk on `virtio0`, NixOS snippet) |
| `storage_pool` | `"VM-pool"` | e.g. `"reflog"` for the reflog project's pool |
| `tags` | `["terraform", <os>]` | |

Identical NixOS nodes go in `local.k8s_hosts` instead, as
`k8s-1 = { vm_id = 120, ip_address = "192.168.1.70/24" }`; they inherit
`local.k8s_spec`.

## Rules

- **The map key is the VM's identity.** Renaming a key, or changing `vm_id` or
  `os`, destroys and recreates the VM. To rename safely:
  `terraform state mv 'module.vm["old"]' 'module.vm["new"]'`.
- **Removing an entry destroys the VM.**
- **`cpu_type` changes need a full stop/start** from Proxmox, not a reboot
  from inside the guest.
- **Don't rename the snippet files on the node** (`qemu-guest-agent.yml`,
  `nixos-vendor.yml`): every VM references them by name and would be
  recreated.
- **Don't edit the `agent` block in the module.** The provider treats any
  change there as needing a reboot and reboots every VM.
- **VM definitions belong in `main.tf`**, never in `terraform.tfvars`, which
  is not versioned.

SSH keys and the snippet only apply at a VM's first boot.

## Troubleshooting

| Symptom | Cause |
|---|---|
| Every plan/apply sits ~15 min at `Refreshing state...` | A running VM's guest agent isn't answering; the provider waits up to 15 min for each. Find it with `qm agent <id> ping` on kyoto. Meanwhile, `-target='module.vm["x"]'` only reads `x`. |
| New VM: apply waits a minute or two | The agent is being installed at first boot. Normal. |
| VM hangs before boot finishes | Template without `virtio-scsi-single`; the module sets it. |
| `Kernel panic - Attempted to kill init` | No serial device; the module adds one. |
| No network, agent never appears | Wrong `gateway` in `terraform.tfvars`. |
| `missing privileges to access local:snippets/...` | API token needs `Datastore.Allocate` on `/storage/local`. |
| `x509: certificate signed by unknown authority` | Set `proxmox_insecure = true`. |
| Unexpected `1 to destroy` | A key was renamed or an entry removed. |

## Tailscale

New VMs join with a reusable auth key minted from the Tailscale OAuth client in
`terraform.tfvars`, tagged `tag:homelab` (`tailscale_tags`). The key lasts 90
days and Terraform replaces it once expired. VMs created before Tailscale was
added are enrolled by `ansible/tailscale.yml`. Set `tailscale_enabled = false`
to stop enrolling new VMs.
