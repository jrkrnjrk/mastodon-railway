#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source /railway/common.sh
# shellcheck disable=SC1091
source /railway/generate-secrets.sh

bootstrap_runtime_env

echo "Mastodon web starting"
echo "  LOCAL_DOMAIN=${LOCAL_DOMAIN:-unset}"
echo "  WEB_DOMAIN=${WEB_DOMAIN:-unset}"
echo "  STREAMING_API_BASE_URL=${STREAMING_API_BASE_URL:-unset}"
echo "  PORT=${PORT:-3000}"

require_var LOCAL_DOMAIN
require_var DATABASE_URL
require_var REDIS_URL

ensure_dir "${PAPERCLIP_ROOT_PATH}"

wait_for_postgres 90
wait_for_redis 60

echo "Running database migrations..."
bundle exec rails db:migrate
echo "Migrations complete."

if [ "${SKIP_ADMIN_BOOTSTRAP:-false}" != "true" ]; then
  echo "Bootstrapping admin account..."
  bundle exec rails runner /railway/bootstrap-admin.rb || echo "Admin bootstrap returned non-zero (continuing)."
fi

export PORT="${PORT:-3000}"
echo "Starting Puma on ${BIND}:${PORT}"
exec bundle exec puma -C config/puma.rb
