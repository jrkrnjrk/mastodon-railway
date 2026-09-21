#!/bin/bash
set -euo pipefail

# Streaming image is slimmer; keep this entrypoint POSIX-friendly and
# independent of Rails helpers.

strip_host() {
  local value="${1:-}"
  value="${value#https://}"
  value="${value#http://}"
  value="${value#wss://}"
  value="${value#ws://}"
  value="${value%%/*}"
  printf '%s' "$value"
}

export NODE_ENV="${NODE_ENV:-production}"
export BIND="${BIND:-0.0.0.0}"
export PORT="${PORT:-4000}"

if [ -z "${DATABASE_URL:-}" ] && [ -n "${POSTGRES_DATABASE_URL:-}" ]; then
  export DATABASE_URL="$POSTGRES_DATABASE_URL"
fi
if [ -z "${REDIS_URL:-}" ] && [ -n "${REDIS_PRIVATE_URL:-}" ]; then
  export REDIS_URL="$REDIS_PRIVATE_URL"
fi

if [ -z "${LOCAL_DOMAIN:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  # Streaming should use the *web* domain, not its own hostname.
  export LOCAL_DOMAIN
  LOCAL_DOMAIN="$(strip_host "${WEB_PUBLIC_DOMAIN:-$RAILWAY_PUBLIC_DOMAIN}")"
elif [ -n "${LOCAL_DOMAIN:-}" ]; then
  export LOCAL_DOMAIN
  LOCAL_DOMAIN="$(strip_host "$LOCAL_DOMAIN")"
fi

echo "Mastodon streaming starting"
echo "  LOCAL_DOMAIN=${LOCAL_DOMAIN:-unset}"
echo "  PORT=${PORT}"
echo "  REDIS_URL set=$( [ -n "${REDIS_URL:-}" ] && echo yes || echo no )"

if [ -z "${REDIS_URL:-}" ]; then
  echo "ERROR: REDIS_URL is not set" >&2
  exit 1
fi
if [ -z "${DATABASE_URL:-}" ]; then
  echo "ERROR: DATABASE_URL is not set" >&2
  exit 1
fi

exec node ./streaming/index.js
