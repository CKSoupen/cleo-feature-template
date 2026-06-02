#!/usr/bin/env bash
# Server-side install for cleo-{{feature_name}}.
# Idempotent — safe to run multiple times.
set -euo pipefail

FEATURE_ID="feat-{{feature_slug}}"
FEATURE_NAME="{{feature_name}}"
INSTALL_DIR="/opt/cleo/infra/agent-features/${FEATURE_NAME}"
CATALOG="/opt/cleo/infra/agent-features/feature-catalog.json"

# --- already installed? ---
if systemctl is-active --quiet "cleo-${FEATURE_NAME}.service" 2>/dev/null; then
  echo "[install] ${FEATURE_NAME} already running — use upgrade.sh to update."
  exit 0
fi

# --- deploy systemd units ---
echo "[install] Deploying systemd units from infra/..."
# TODO: copy infra/*.service to /etc/systemd/system/ and enable them
# cp infra/*.service /etc/systemd/system/
# systemctl daemon-reload
# systemctl enable --now "cleo-${FEATURE_NAME}.service"

# --- register in feature catalog ---
if [ -f "$CATALOG" ]; then
  echo "[install] Registering ${FEATURE_ID} in feature-catalog.json..."
  # TODO: use jq to upsert the feature entry in $CATALOG
  # jq --argjson entry "$(cat infra/catalog-entry.json)" \
  #   '.features |= (map(select(.feature_id != $entry.feature_id)) + [$entry])' \
  #   "$CATALOG" > "${CATALOG}.tmp" && mv "${CATALOG}.tmp" "$CATALOG"
else
  echo "[install] Warning: feature-catalog.json not found at ${CATALOG} — skipping registration."
fi

echo "[install] ${FEATURE_NAME} installed."
