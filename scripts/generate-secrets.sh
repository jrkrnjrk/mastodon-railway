#!/bin/bash
# Fill any missing Mastodon secrets and persist them on the media volume
# so a redeploy does not rotate keys.
set -euo pipefail

SECRETS_FILE="${SECRETS_FILE:-/opt/mastodon/public/system/.railway/secrets.env}"

load_persisted_secrets "$SECRETS_FILE"

if [ -z "${SECRET_KEY_BASE:-}" ]; then
  export SECRET_KEY_BASE
  SECRET_KEY_BASE="$(generate_hex 64)"
  echo "Generated SECRET_KEY_BASE (persisted on volume)."
fi

if [ -z "${OTP_SECRET:-}" ]; then
  export OTP_SECRET
  OTP_SECRET="$(generate_hex 64)"
  echo "Generated OTP_SECRET (persisted on volume)."
fi

if [ -z "${ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY:-}" ]; then
  export ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY="$(generate_hex 32)"
  echo "Generated ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY (persisted on volume)."
fi

if [ -z "${ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY:-}" ]; then
  export ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
  ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY="$(generate_hex 32)"
  echo "Generated ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY (persisted on volume)."
fi

if [ -z "${ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT:-}" ]; then
  export ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT="$(generate_hex 32)"
  echo "Generated ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT (persisted on volume)."
fi

if [ -z "${VAPID_PRIVATE_KEY:-}" ] || [ -z "${VAPID_PUBLIC_KEY:-}" ]; then
  echo "Generating VAPID keys..."
  vapid_out="$(bundle exec rake mastodon:webpush:generate_vapid_key 2>/dev/null || true)"
  if [ -z "${VAPID_PRIVATE_KEY:-}" ]; then
    export VAPID_PRIVATE_KEY
    VAPID_PRIVATE_KEY="$(printf '%s\n' "$vapid_out" | awk -F= '/VAPID_PRIVATE_KEY=/ {print $2; exit}')"
  fi
  if [ -z "${VAPID_PUBLIC_KEY:-}" ]; then
    export VAPID_PUBLIC_KEY
    VAPID_PUBLIC_KEY="$(printf '%s\n' "$vapid_out" | awk -F= '/VAPID_PUBLIC_KEY=/ {print $2; exit}')"
  fi
  if [ -z "${VAPID_PRIVATE_KEY:-}" ] || [ -z "${VAPID_PUBLIC_KEY:-}" ]; then
    echo "ERROR: failed to generate VAPID keys" >&2
    exit 1
  fi
  echo "Generated VAPID keys (persisted on volume)."
fi

persist_secret_file "$SECRETS_FILE"

echo
echo "============================================================"
echo "Copy these into Railway Variables if you have not already."
echo "Do not rotate them after the instance has users."
echo "------------------------------------------------------------"
echo "SECRET_KEY_BASE=${SECRET_KEY_BASE}"
echo "OTP_SECRET=${OTP_SECRET}"
echo "VAPID_PRIVATE_KEY=${VAPID_PRIVATE_KEY}"
echo "VAPID_PUBLIC_KEY=${VAPID_PUBLIC_KEY}"
echo "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=${ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY}"
echo "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=${ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY}"
echo "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=${ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT}"
echo "============================================================"
echo
