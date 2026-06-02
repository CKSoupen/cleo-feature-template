#!/usr/bin/env bash
# Server-side uninstall for cleo-{{feature_name}}.
# Checks for active subscribers before removing.
set -euo pipefail

FEATURE_ID="feat-{{feature_slug}}"
FEATURE_NAME="{{feature_name}}"
CATALOG="/opt/cleo/infra/agent-features/feature-catalog.json"

# --- check for active subscribers ---
if [ -f "$CATALOG" ]; then
  SUBSCRIBERS=$(jq -r --arg fid "$FEATURE_ID" \
    '.features[] | select(.feature_id == $fid) | .subscribers | length' "$CATALOG" 2>/dev/null || echo "0")
  if [ "${SUBSCRIBERS:-0}" -gt 0 ]; then
    echo "[uninstall] Error: ${FEATURE_ID} has ${SUBSCRIBERS} active subscriber(s). Unsubscribe all users first."
    exit 1
  fi
fi

# --- stop and disable systemd units ---
echo "[uninstall] Stopping and disabling systemd units..."
# TODO: stop + disable + remove units
# systemctl stop "cleo-${FEATURE_NAME}.service" || true
# systemctl disable "cleo-${FEATURE_NAME}.service" || true
# rm -f "/etc/systemd/system/cleo-${FEATURE_NAME}.service"
# systemctl daemon-reload

# --- remove from feature catalog ---
if [ -f "$CATALOG" ]; then
  echo "[uninstall] Removing ${FEATURE_ID} from feature-catalog.json..."
  # TODO: jq delete entry
  # jq --arg fid "$FEATURE_ID" 'del(.features[] | select(.feature_id == $fid))' \
  #   "$CATALOG" > "${CATALOG}.tmp" && mv "${CATALOG}.tmp" "$CATALOG"
fi

echo "[uninstall] ${FEATURE_NAME} uninstalled."
