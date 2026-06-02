#!/usr/bin/env bash
# Per-user subscribe for cleo-{{feature_name}}.
# Posts feature.subscribe.infra.complete on success.
set -euo pipefail

FEATURE_ID="feat-{{feature_slug}}"
FEATURE_NAME="{{feature_name}}"
EB="/opt/cleo/infra/eventbridge/.venv/bin/eb"

usage() {
  echo "Usage: $0 --user <username>"
  exit 1
}

USER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) USER="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[ -z "$USER" ] && usage

# --- resolve vault path ---
VAULT_PATH="/opt/cleo/vaults/${USER}"
if [ ! -d "$VAULT_PATH" ]; then
  echo "[subscribe] Error: vault not found for user '${USER}' at ${VAULT_PATH}"
  exit 1
fi

# --- per-user service setup ---
# TODO: create or configure user-scoped service if multi-user services exist
# Example: systemctl enable --now "cleo-${FEATURE_NAME}@${USER}.service"

# --- post EB event ---
echo "[subscribe] Posting feature.subscribe.infra.complete for ${FEATURE_ID} / ${USER}..."
echo "{\"feature_id\": \"${FEATURE_ID}\", \"user\": \"${USER}\"}" | \
  "$EB" publish --source "cleo-${FEATURE_NAME}" --user "${USER}" \
  feature.subscribe.infra.complete

echo "[subscribe] ${USER} subscribed to ${FEATURE_NAME}."
