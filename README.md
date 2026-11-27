# homelab

Infrastructure for a single Proxmox node, `kyoto` (192.168.1.160), managed as
code.

| Directory | Tool | Manages |
|---|---|---|
| [`terraform/`](terraform/README.md) | Terraform (bpg/proxmox) | The VMs themselves, cloned from templates |
| [`ansible/`](ansible/README.md) | Ansible | What runs inside them |
| [`nixos/template/`](nixos/template/README.md) | Nix flake | The NixOS template (VM 9001) |
| `policy.json` | Tailscale | Tailnet access policy (paste into the admin console) |

## Machines

| VM | ID | IP | Role |
|---|---|---|---|
| smb | 100 (LXC) | .100 | NAS (Samba), backup target |
| nextcloud | 101 | .60 | Nextcloud |
| atm10 | 102 | .80 | Minecraft server (All The Mods 10) |
| monitoring | 103 | .81 | Prometheus / Grafana |
| momo | 104 | .82 | A friend's website (Next.js) |
| pwn | 105 | .170 | |
| imotep | 106 | .90 | |
| reflog-registry | 107 | .87 | Private Docker registry (Tailscale only) |
| reflog-preview | 108 | .88 | reflog preview environment |
| cloudflared | 300 | .83 | Every Cloudflare Tunnel |
| templates | 9000, 9001 | | Debian 13 and NixOS cloud-init templates |

LAN `192.168.1.0/24`, gateway `.1`. Static VM addresses must stay outside the
router's DHCP range.

## Access

- **Tailscale** (tailnet `zetsumeii.github`): every VM joins at first boot,
  tagged `tag:homelab`. kyoto is reachable at `100.112.238.87` and is the
  subnet router for the LAN, so the whole homelab works from anywhere.
  Policy in `policy.json`; CI jobs (`tag:ci`) may only reach the registry.
- **Cloudflare Tunnel**: public sites go through the `kyoto` tunnel on the
  cloudflared VM (`/etc/cloudflared/config.yml`). The Cloudflare account is
  shared with a coworker: don't delete tunnels or DNS records you don't own.

## From zero

1. Templates exist on kyoto (9000 Debian, 9001 NixOS, see `nixos/template`).
2. `terraform/`: fill `terraform.tfvars`, then `terraform init && terraform apply`.
3. `ansible/`: create the vault files listed in its README, then run the
   playbooks (`infra.yml` first).

## Secrets

Never in git unencrypted. `terraform/terraform.tfvars` is gitignored; Ansible
secrets are vault-encrypted under `ansible/vars/`. Enable the pre-commit hook
that enforces it once per clone:

```sh
git config core.hooksPath .githooks
```
