#!/bin/bash
set -euo pipefail
source /railway/common.sh
source /railway/generate-secrets.sh
bootstrap_runtime_env

echo "Mastodon web starting"
echo "  LOCAL_DOMAIN=${LOCAL_DOMAIN:-unset}"
echo "  WEB_DOMAIN=${WEB_DOMAIN:-unset}"
echo "  STREAMING_API_BASE_URL=${STREAMING_API_BASE_URL:-unset}"
echo "  PORT=${PORT:-3000}"
echo "  DATABASE_URL=$(echo "${DATABASE_URL:-}" | sed -E 's#://([^:]+):[^@]+@#://\1:***@#')"
echo "  REDIS_URL=$(echo "${REDIS_URL:-}" | sed -E 's#://([^:]+):[^@]+@#://\1:***@#')"

require_var LOCAL_DOMAIN
require_var DATABASE_URL
require_var REDIS_URL
ensure_dir "${PAPERCLIP_ROOT_PATH}"

export PORT="${PORT:-3000}"
echo "Running database migrations (visible)..."
bundle exec rails db:migrate
echo "Migrations complete."

if [ "${SKIP_ADMIN_BOOTSTRAP:-false}" != "true" ]; then
  echo "Bootstrapping admin account..."
  bundle exec rails runner /railway/bootstrap-admin.rb || echo "Admin bootstrap returned non-zero (continuing)."
fi

echo "Starting Puma on ${BIND}:${PORT}"
exec bundle exec puma -C config/puma.rb