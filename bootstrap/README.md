# bootstrap-user.sh

Provision a standard sudo user on a Proxmox LXC — key-only login,
passwordless sudo, optional git identity. Runs in two modes: locally
inside the container, or remotely over SSH from `iac-mgmt`.

## Purpose

Creates a consistent `sfoster` (or named) account on a freshly created LXC
before any other tooling (Ansible, Terraform remote-exec) can reach it.
Handles the full setup in one pass: installs `sudo` if absent, creates the
user, writes the sudoers drop-in, and places the public key.

## Flags

| Flag | Required | Default | Description |
|---|---|---|---|
| `--pubkey <path>` | Yes | — | Path to the public key file to install |
| `--mode <local\|remote>` | Yes | — | Execution mode (see below) |
| `--host <ip\|hostname>` | remote only | — | Target to SSH into as root |
| `--user <name>` | No | `sfoster` | Account to create or update |
| `--git-name <name>` | No | — | git `user.name` (set only if both git flags given) |
| `--git-email <email>` | No | — | git `user.email` (set only if both git flags given) |

`--git-name` and `--git-email` are only needed on boxes that commit to git
(e.g. `iac-mgmt`). Omit both on containers that don't need a git identity.

## Modes

**local** — run the script directly inside the container. Requires root.
The typical entry point is `pct enter <vmid>` on the Proxmox host, which
drops you into a root shell inside the container.

**remote** — run from `iac-mgmt` (or any host with root SSH trust to the
target). The script SSHes into the target as root and executes the
provisioning inline. Requires that root SSH access to the target already
exists (e.g. Proxmox injects the host's root key at container creation).

## Usage

**Local mode** (inside the container after `pct enter <vmid>`):

```bash
./bootstrap-user.sh --pubkey ~/.ssh/id_ed25519.pub --mode local
```

**Remote mode** (from `iac-mgmt`, targeting a new LXC):

```bash
./bootstrap-user.sh \
  --pubkey ~/.ssh/id_ed25519.pub \
  --mode remote \
  --host 192.168.1.188 \
  --git-name "Steve Foster" \
  --git-email "steven.foster76@gmail.com"
```

## Important

- Minimal LXC templates (Debian, Ubuntu) often ship without `sudo`. The
  script runs `apt-get install -y sudo` before attempting `usermod`, so it
  is safe to run on a bare container.
- The script is idempotent: the user is created only if absent, and
  `authorized_keys` is overwritten (not appended) on every run. Safe to
  re-run if the key changes or provisioning is interrupted.
- The sudoers drop-in is validated with `visudo -cf` before it is placed.
  If the file fails validation the script aborts without installing a broken
  sudoers entry.
- In remote mode the public key content and git values are passed on the SSH
  command line and are briefly visible in the process list on the Proxmox
  host. This is acceptable on a trusted LAN but avoid using this mode over
  an untrusted network.
- Directories created or written by services that previously ran as root will
  be owned by root and inaccessible to `sfoster`. Fix ownership after
  bootstrapping wherever this applies:
  ```bash
  sudo chown -R sfoster:sfoster /opt/mediaconfig
  ```
  Check any other paths the container's services write to (config dirs,
  data dirs, log dirs) and apply the same pattern as needed.
- When staging the script from `pve-tank12` (e.g. before `pct push`), pull
  from `iac-mgmt` as root:
  ```bash
  scp root@192.168.1.13:/opt/homelab/bootstrap/bootstrap-user.sh /tmp/
  ```
  `pve-tank12` has root-to-root SSH trust to `iac-mgmt` but no `sfoster`
  key, so `scp sfoster@...` will fail with a password prompt.
