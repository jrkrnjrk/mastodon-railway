#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /railway/common.sh

bootstrap_runtime_env
SECRETS_FILE="${SECRETS_FILE:-/opt/mastodon/public/system/.railway/secrets.env}"
echo "Waiting for secrets from web bootstrap (shared volume)..."
for i in $(seq 1 60); do
  load_persisted_secrets "$SECRETS_FILE"
  if [ -n "${SECRET_KEY_BASE:-}" ] && [ -n "${ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY:-}" ]; then
    break
  fi
  sleep 2
done

echo "Mastodon Sidekiq starting"
echo "  LOCAL_DOMAIN=${LOCAL_DOMAIN:-unset}"
echo "  SIDEKIQ_CONCURRENCY=${SIDEKIQ_CONCURRENCY:-5}"

require_var LOCAL_DOMAIN
require_var DATABASE_URL
require_var REDIS_URL
require_var SECRET_KEY_BASE
require_var ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY

ensure_dir "${PAPERCLIP_ROOT_PATH}"

wait_for_postgres 90
wait_for_redis 60

export SIDEKIQ_CONCURRENCY="${SIDEKIQ_CONCURRENCY:-5}"
exec bundle exec sidekiq -c "${SIDEKIQ_CONCURRENCY}"
