#!/usr/bin/env bash
# Run from: /opt/homelab/servers/pve-tank12/ilo/
# Dry-run first: bash fix-hostnames.sh --dry-run

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

FILES=(apply-ilo.sh README.md)

for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || { echo "Not found: $f" >&2; continue; }
  updated="$(sed \
    -e 's/hpe-tank12\.fosternet\.home/pve-tank12.fosternet.home/g' \
    -e 's/ilo-hpe-tank12\.fosternet\.home/ilo-pve-tank12.fosternet.home/g' \
    -e 's/ilo-hpe-tank12/ilo-pve-tank12/g' \
    -e 's/hpe-tank12/pve-tank12/g' \
    "$f")"
  if $DRY_RUN; then
    echo "──── $f ────"
    diff <(cat "$f") <(echo "$updated") || true
  else
    echo "$updated" > "$f"
    echo "Updated: $f"
  fi
done
