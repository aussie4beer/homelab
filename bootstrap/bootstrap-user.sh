#!/usr/bin/env bash
# bootstrap-user.sh — provision a standard sudo user on a Proxmox LXC
# Repo:    aussie4beer/homelab  ->  homelab/bootstrap/bootstrap-user.sh
# Purpose: Create a key-only login user with passwordless sudo on a target LXC.
# Modes:   local  — run inside the container (e.g. after `pct enter <vmid>`)
#          remote — run from iac-mgmt, SSH into the target as root
# Usage:   ./bootstrap-user.sh --pubkey ~/.ssh/id_ed25519.pub --mode local
#          ./bootstrap-user.sh --pubkey ~/.ssh/id_ed25519.pub --mode remote --host 192.168.1.188
# Note:    Installs sudo first (minimal LXC templates often lack it).

set -euo pipefail

USERNAME="sfoster"
MODE=""
HOST=""
PUBKEY_PATH=""
GIT_NAME=""
GIT_EMAIL=""

usage() {
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --pubkey)    PUBKEY_PATH="$2"; shift 2 ;;
        --mode)      MODE="$2"; shift 2 ;;
        --host)      HOST="$2"; shift 2 ;;
        --user)      USERNAME="$2"; shift 2 ;;
        --git-name)  GIT_NAME="$2"; shift 2 ;;
        --git-email) GIT_EMAIL="$2"; shift 2 ;;
        -h|--help)   usage ;;
        *)           echo "Unknown arg: $1" >&2; usage ;;
    esac
done

[[ -z "$PUBKEY_PATH" ]] && { echo "ERROR: --pubkey is required" >&2; usage; }
[[ ! -f "$PUBKEY_PATH" ]] && { echo "ERROR: pubkey not found: $PUBKEY_PATH" >&2; exit 1; }
[[ "$MODE" != "local" && "$MODE" != "remote" ]] && { echo "ERROR: --mode must be local or remote" >&2; usage; }
[[ "$MODE" == "remote" && -z "$HOST" ]] && { echo "ERROR: --mode remote requires --host" >&2; exit 1; }

PUBKEY_CONTENT="$(cat "$PUBKEY_PATH")"

case "$PUBKEY_CONTENT" in
    ssh-ed25519\ *|ssh-rsa\ *|ecdsa-sha2-*\ *) : ;;
    *) echo "ERROR: $PUBKEY_PATH doesn't look like a public key" >&2; exit 1 ;;
esac

provision() {
cat <<'PROVISION'
set -euo pipefail

if ! command -v sudo >/dev/null 2>&1; then
    apt-get update
    apt-get install -y sudo
fi

if ! id "$BS_USER" >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" "$BS_USER"
fi

usermod -aG sudo "$BS_USER"

echo "$BS_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$BS_USER"
chmod 440 "/etc/sudoers.d/$BS_USER"
visudo -cf "/etc/sudoers.d/$BS_USER"

install -d -m 700 -o "$BS_USER" -g "$BS_USER" "/home/$BS_USER/.ssh"
echo "$BS_PUBKEY" > "/home/$BS_USER/.ssh/authorized_keys"
chmod 600 "/home/$BS_USER/.ssh/authorized_keys"
chown "$BS_USER:$BS_USER" "/home/$BS_USER/.ssh/authorized_keys"

if [[ -n "$BS_GIT_NAME" && -n "$BS_GIT_EMAIL" ]]; then
    sudo -u "$BS_USER" git config --global user.name "$BS_GIT_NAME"
    sudo -u "$BS_USER" git config --global user.email "$BS_GIT_EMAIL"
fi

echo "OK: $BS_USER provisioned on $(hostname)"
id "$BS_USER"
PROVISION
}

export BS_USER="$USERNAME"
export BS_PUBKEY="$PUBKEY_CONTENT"
export BS_GIT_NAME="$GIT_NAME"
export BS_GIT_EMAIL="$GIT_EMAIL"

if [[ "$MODE" == "local" ]]; then
    [[ "$(id -u)" -ne 0 ]] && { echo "ERROR: local mode must run as root (try: pct enter <vmid>)" >&2; exit 1; }
    provision | BS_USER="$BS_USER" BS_PUBKEY="$BS_PUBKEY" BS_GIT_NAME="$BS_GIT_NAME" BS_GIT_EMAIL="$BS_GIT_EMAIL" bash
else
    provision | ssh "root@$HOST" \
        "BS_USER='$BS_USER' BS_PUBKEY='$BS_PUBKEY' BS_GIT_NAME='$BS_GIT_NAME' BS_GIT_EMAIL='$BS_GIT_EMAIL' bash"
fi
