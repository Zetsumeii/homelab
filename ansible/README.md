# Ansible

Configures the VMs Terraform creates. Run everything from this directory:
`ansible.cfg` points at `inventory.yml`, so no `-i` is needed.

```sh
ansible-galaxy collection install -r requirements.yml   # once
ansible-playbook <playbook>.yml --ask-vault-pass --check  # dry run
ansible-playbook <playbook>.yml --ask-vault-pass
```

## Playbooks

| Playbook | Hosts | Does |
|---|---|---|
| `infra.yml` | `reflog` | Base setup: apt upgrade, packages, Docker, ufw, users. Other plays are commented out until needed. |
| `tailscale.yml` | all VMs except `smb`, `proxmox`, `k8s` | Installs Tailscale and joins the tailnet. Skips nodes already joined. |
| `proxmox.yml` | `proxmox` (kyoto) | Makes kyoto the subnet router for `192.168.1.0/24`. |
| `backup.yml` | `smb`, `atm10` | NAS share for backups, then restic backups of the atm10 server. |
| `reflog.yml` | `reflog_registry`, `reflog_preview` | Docker registry on Tailscale; Docker on the preview VM. |
| `update_keys.yml` | all VMs except `smb`, `proxmox`, `k8s` | Re-applies the `users` role (account, sudo, SSH keys). |

`k8s` is the NixOS group: those nodes are configured from their flake, never
by these Debian roles. Keep it excluded from new playbooks.

## Secrets

All secrets are vault-encrypted, with one shared vault password.

| File | Holds | Loaded by |
|---|---|---|
| `vars/users.yml` | `worker_password` | `infra.yml`, `update_keys.yml` |
| `vars/tailscale.yml` | `tailscale_auth_key` (the Tailscale OAuth client secret) | `tailscale.yml` |
| `vars/backup.yml` | `backup_smb_password`, `minecraft_backup_restic_password` | `backup.yml` |
| `vars/reflog.yml` | `registry_users` | `reflog.yml` |
| `group_vars/nextcloud/secrets.yml` | `vault_nextcloud_*` passwords | automatically, for `nextcloud` |
| `roles/monitoring/vars/main.yml` | Grafana admin credentials | the `monitoring` role |

```sh
ansible-vault create vars/<name>.yml
ansible-vault edit vars/<name>.yml
```

The repo's pre-commit hook (`.githooks/`) refuses to commit `vars/*.yml` or
`group_vars/*/secrets.yml` unencrypted. Enable it once per clone with
`git config core.hooksPath .githooks`.

Never set a secret in a role's `vars/`: role vars outrank `vars_files`, so it
would silently win over the vault.

## Roles

Tunables are in each role's `defaults/main.yml`; `vars/main.yml` holds internals.

### smb

Samba on the NAS container. **It replaces `smb.conf`**: any share or user not
listed in `group_vars/smb.yml` is removed on the next run.

```yaml
samba_users:
  - name: alice
    password: "{{ vault_samba_alice_password }}"
    groups: [media]            # optional
samba_shares:
  - name: media
    path: /srv/nas/media       # default: <samba_share_root>/<name>
    valid_users: ["@smbusers"] # default: ["@<samba_group>"]
    read_only: false
    browseable: true
    recycle: true              # deletes go to .recycle
```

### nextcloud

Nextcloud, Postgres and Redis with Docker Compose. Passwords come from
`group_vars/nextcloud/secrets.yml` (`vault_nextcloud_db_password`,
`vault_nextcloud_redis_password`, `vault_nextcloud_admin_password`) and are
written to a `0600` `.env`; compose refuses to start if one is empty.

### tailscale, tailscale_router

`tailscale` installs from Tailscale's apt repo and joins with the OAuth secret
from `vars/tailscale.yml`, tagged `tag:homelab`. OAuth-joined nodes are made
non-ephemeral, otherwise Tailscale deletes them once they go offline. Flags in
`tailscale_up_args` only apply on first join; change them later with
`tailscale set`.

`tailscale_router` (kyoto) advertises `tailscale_router_routes` and enables IP
forwarding. A new route must be approved in the admin console (Machines →
kyoto → Edit route settings). Clients need `--accept-routes`.

### minecraft_backup

Restic backups of atm10 to the NAS every 2 hours, consistent even while the
server runs: `save-off`, `save-all flush`, wait for `Saved the game`, snapshot,
then `save-on`, sent whatever happens. A weekly job prunes and checks.

On atm10, as root, load the repository settings first:

```sh
set -a; . /etc/minecraft-backup/atm10/restic.env; set +a
systemctl list-timers 'atm10-backup*'      # next and last runs
journalctl -u atm10-backup.service -n 40   # last run
restic snapshots --tag atm10
systemctl start atm10-backup.service       # back up now
```

Restore the world:

```sh
systemctl stop atm10.service
mv /opt/atm10/server/world /opt/atm10/server/world.before-restore
restic restore <ID> --target / --include /opt/atm10/server/world
systemctl start atm10.service
```

Don't stop atm10 by hand during a backup, or it goes down with autosave off.
If the journal says `could not re-enable autosave`, run
`echo save-on > /run/atm10.stdin`.

### docker_registry

Private registry (distribution v3), reachable only over Tailscale at
`https://reflog-registry.tailece7b2.ts.net`. The container listens on
`127.0.0.1:5000` and `tailscale serve` publishes it with a certificate
Tailscale renews. Requires HTTPS certificates enabled for the tailnet (admin
console → DNS).

Users come from `registry_users` in `vars/reflog.yml`; that list is
authoritative, so removed users are deleted.

```yaml
registry_users:
  - { name: zetsumei, password: "..." }
  - { name: ci, password: "..." }
```

Reclaim space after deleting tags:

```sh
cd /opt/registry && sudo docker compose stop
sudo docker compose run --rm registry garbage-collect --delete-untagged /etc/distribution/config.yml
sudo docker compose start
```

### github_runner

Self-hosted GitHub Actions runner as `github-runner.service`. Registering needs
admin on the repo: pass a one-hour token from the repo's
*Settings → Actions → Runners → New self-hosted runner* with
`-e github_runner_registration_token=...`, or vault a PAT in
`github_runner_pat`. Use it from private repos only: workflow jobs get root on
the VM through Docker.
