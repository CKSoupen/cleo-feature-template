#!/usr/bin/env bash
# Per-user unsubscribe for cleo-{{feature_name}}.
# Posts feature.unsubscribe.infra.complete on success.
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

# --- per-user service teardown ---
# TODO: stop and disable user-scoped service if applicable
# Example: systemctl disable --now "cleo-${FEATURE_NAME}@${USER}.service"

# --- post EB event ---
echo "[unsubscribe] Posting feature.unsubscribe.infra.complete for ${FEATURE_ID} / ${USER}..."
echo "{\"feature_id\": \"${FEATURE_ID}\", \"user\": \"${USER}\"}" | \
  "$EB" publish --source "cleo-${FEATURE_NAME}" --user "${USER}" \
  feature.unsubscribe.infra.complete

echo "[unsubscribe] ${USER} unsubscribed from ${FEATURE_NAME}."
