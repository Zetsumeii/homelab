# NixOS template (VM 9001)

The base image Terraform clones for VMs with `os = "nixos"`. It only holds
what Proxmox and Terraform need: guest agent, cloud-init, key-only SSH,
tailscaled and flakes. Anything a node is for (Kubernetes, its role) belongs
in the cluster's own flake, deployed with `nixos-rebuild --target-host`,
colmena or deploy-rs, so the image rarely needs rebuilding.

## What a clone gets

| From | What |
|---|---|
| Proxmox cloud-init (Terraform's `initialization`) | hostname = VM name, static IP, `ci_user` with your SSH keys, in `wheel` (passwordless sudo) |
| `terraform/snippets/cloud-init-nixos.yaml.tftpl` | `tailscale up` with the minted key |
| This image | root disk on **virtio0** (`/dev/vda`), grows to the Terraform `disk_size` on first boot |

## Rebuilding and re-importing

The build runs in a throwaway container, so Nix isn't needed locally; `/dev/kvm` must exist.

```sh
cd nixos/template
docker run --rm --device /dev/kvm -v nix-template-store:/nix -v "$PWD":/src -w /src \
  nixos/nix:2.35.2 sh -c '
    NIX="nix --extra-experimental-features nix-command --extra-experimental-features flakes \
         --option system-features kvm --option sandbox false"
    out=$($NIX build .#vma --no-link --print-out-paths) && mkdir -p out && cp -f "$out"/*.vma.zst out/'
```

`nix flake update` in the same container bumps nixpkgs; commit `flake.lock`.

Then on kyoto, replacing the old template (VMs already cloned from it are
full clones and are not affected):

```sh
scp out/vzdump-qemu-nixos-template.vma.zst root@kyoto:/var/lib/vz/dump/
ssh root@kyoto '
  qm destroy 9001
  qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-template.vma.zst 9001 --storage VM-pool --unique 1
  qm set 9001 --boot order=virtio0 --delete ide2
  pvesm free VM-pool:vm-9001-cloudinit
  qm set 9001 --ide2 VM-pool:cloudinit --tags nixos,template
  qm set 9001 --net0 "$(qm config 9001 | sed -n "s/^net0: //p" | sed "s/,firewall=1//")"
  qm template 9001
  rm /var/lib/vz/dump/vzdump-qemu-nixos-template.vma.zst'
```

Why each line:

- `--unique 1` gives the NIC a random MAC (the image ships `00:00:00:00:00:00`).
- The image's `boot:` line is empty, so Proxmox would not know what to boot.
- The restored cloud-init drive is recreated so Proxmox regenerates it.
- The image enables the Proxmox firewall on the NIC; the other VMs have it off.
- Three `unable to parse config: additionalSpace/bootSize/diskSize` warnings
  during the restore are build parameters nixpkgs writes into the backup.
  Proxmox ignores them.

## Gotchas

- **The disk is `virtio0`, not `scsi0`.** Terraform handles it through
  `os = "nixos"`. Anything cloning by hand must attach nothing on `scsi0`,
  and `nixos-rebuild` on the clone keeps installing GRUB to `/dev/vda`.
- **Keep qemu-guest-agent running** in whatever the cluster flake deploys. The
  Proxmox provider waits up to 15 minutes for every running VM's agent on each
  plan and apply, so one VM with a dead agent stalls Terraform for everything.
