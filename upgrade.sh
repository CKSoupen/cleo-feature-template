#!/usr/bin/env bash
# Upgrade cleo-{{feature_name}} — uninstall + reinstall + notify subscribers.
set -euo pipefail

FEATURE_ID="feat-{{feature_slug}}"
FEATURE_NAME="{{feature_name}}"
EB="/opt/cleo/infra/eventbridge/.venv/bin/eb"
CATALOG="/opt/cleo/infra/agent-features/feature-catalog.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[upgrade] Starting upgrade for ${FEATURE_NAME}..."

# --- collect subscribers before uninstall ---
SUBSCRIBERS=()
if [ -f "$CATALOG" ]; then
  mapfile -t SUBSCRIBERS < <(jq -r --arg fid "$FEATURE_ID" \
    '.features[] | select(.feature_id == $fid) | .subscribers[]' "$CATALOG" 2>/dev/null || true)
fi

# --- uninstall + reinstall ---
"${SCRIPT_DIR}/uninstall.sh"
"${SCRIPT_DIR}/install.sh"

# --- notify subscribers via EB ---
for user in "${SUBSCRIBERS[@]}"; do
  echo "[upgrade] Posting upgrade notification for ${user}..."
  echo "{\"feature_id\": \"${FEATURE_ID}\", \"user\": \"${user}\"}" | \
    "$EB" publish --source "cleo-${FEATURE_NAME}" --user "${user}" \
    "feature.${FEATURE_NAME}.upgraded" || true
done

echo "[upgrade] ${FEATURE_NAME} upgrade complete."
