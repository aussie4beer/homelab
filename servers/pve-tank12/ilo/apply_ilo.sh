#!/usr/bin/env bash
# apply-ilo.sh — Apply iLO 4 RIBCL configuration templates to pve-tank12.
#
# Usage:
#   ./apply-ilo.sh [--host <ip>] [--dry-run] [template1.xml.tmpl ...]
#
#   --host      Override the default iLO IP (default: 192.168.1.139)
#   --dry-run   Print substituted XML to stdout; do not send to iLO
#
#   If no templates are specified, all *.xml.tmpl files in the same
#   directory as this script are applied in alphabetical order.
#
# Requirements:
#   curl, bash 4+
#
# SSH note (if using the iLO SSH interface instead):
#   Add to ~/.ssh/config:
#     Host 192.168.1.139
#       KexAlgorithms +diffie-hellman-group14-sha1
#       HostKeyAlgorithms +ssh-rsa
#       PubkeyAcceptedKeyTypes +ssh-rsa

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
ILO_HOST="192.168.1.139"
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES=()

# ── Argument parsing ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      ILO_HOST="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *.xml.tmpl)
      TEMPLATES+=("$1")
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# If no templates specified, glob all in script directory
if [[ ${#TEMPLATES[@]} -eq 0 ]]; then
  mapfile -t TEMPLATES < <(find "$SCRIPT_DIR" -maxdepth 1 -name '*.xml.tmpl' | sort)
fi

if [[ ${#TEMPLATES[@]} -eq 0 ]]; then
  echo "No .xml.tmpl files found in $SCRIPT_DIR" >&2
  exit 1
fi

# ── Password prompt ───────────────────────────────────────────────────────────
if [[ "${ILO_PASS:-}" == "" ]]; then
  read -rsp "iLO password for ${ILO_HOST}: " ILO_PASS
  echo
fi

if [[ -z "$ILO_PASS" ]]; then
  echo "No password provided." >&2
  exit 1
fi

# ── Apply templates ───────────────────────────────────────────────────────────
PASS_COUNT=0
FAIL_COUNT=0

apply_template() {
  local tmpl="$1"
  local name
  name="$(basename "$tmpl")"

  # Substitute placeholder — operate in memory, never write to disk
  local xml
  xml="$(sed "s/{{ ilo_password }}/${ILO_PASS}/g" "$tmpl")"

  if $DRY_RUN; then
    echo "──── DRY RUN: ${name} ────"
    echo "$xml"
    echo
    return 0
  fi

  echo -n "  Applying ${name} ... "

  local response
  response="$(
    printf '%s' "$xml" \
      | curl \
          --silent \
          --show-error \
          --insecure \
          --max-time 15 \
          --data-binary @- \
          "https://${ILO_HOST}/ribcl" \
        2>&1
  )"

  # iLO 4 RIBCL returns XML; a successful apply contains STATUS_TAG VALUE="0x0000"
  if echo "$response" | grep -q 'VALUE="0x0000"'; then
    echo "OK"
    return 0
  else
    echo "FAILED"
    echo "    Response: ${response}" >&2
    return 1
  fi
}

echo "Applying ${#TEMPLATES[@]} template(s) to iLO at ${ILO_HOST}"
echo

for tmpl in "${TEMPLATES[@]}"; do
  if apply_template "$tmpl"; then
    (( PASS_COUNT++ ))
  else
    (( FAIL_COUNT++ ))
  fi
done

echo
echo "Done — ${PASS_COUNT} succeeded, ${FAIL_COUNT} failed."

[[ $FAIL_COUNT -eq 0 ]]
