#!/bin/sh
# SendDock on Railway: assemble the connection URLs, bind to the injected PORT, run the stock entrypoint (goose migrations, then the
# server), and create the administrator from variables as soon as the server answers.
set -eu
cd /app

need() { eval "v=\${$1:-}"; [ -n "$v" ] || { echo "[railway-boot] $1 is required" >&2; exit 1; }; }
for n in JWT_SECRET DB_HOST DB_USER DB_PASS DB_NAME REDIS_HOST REDIS_PASS SENDDOCK_ADMIN_EMAIL SENDDOCK_ADMIN_PASSWORD; do need "$n"; done

# Railway's healthcheck and edge dial the injected PORT.
PORT="${PORT:-8080}"
export PORT
export DATABASE_URL="postgres://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_NAME?sslmode=disable"
export REDIS_URL="redis://:$REDIS_PASS@$REDIS_HOST:6379"
[ -z "${RAILWAY_PUBLIC_DOMAIN:-}" ] || export PUBLIC_URL="https://$RAILWAY_PUBLIC_DOMAIN"

# GET /api/v1/setup/status says setup_required while no user exists. POST /api/v1/setup then creates the first user (and stores the
# public URL). Both are open to any caller until that first user exists, so do it as soon as /health answers, and only while
# setup_required is true so a redeploy never touches an existing instance.
(
  base="http://127.0.0.1:$PORT"
  i=0
  until curl -fsS -o /dev/null "$base/health" 2>/dev/null; do
    i=$((i+1)); [ "$i" -le 180 ] || { echo "[railway-boot] server never answered, administrator not created" >&2; exit 0; }; sleep 1
  done
  need_setup=$(curl -fsS "$base/api/v1/setup/status" | jq -r '.setup_required | tostring' || true)
  if [ "$need_setup" = "true" ]; then
    body=$(jq -nc --arg n "${SENDDOCK_ADMIN_NAME:-Admin}" --arg e "$SENDDOCK_ADMIN_EMAIL" --arg p "$SENDDOCK_ADMIN_PASSWORD" --arg u "${PUBLIC_URL:-}" \
      '{name:$n,email:$e,password:$p,public_url:$u}')
    code=$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$base/api/v1/setup" -H 'content-type: application/json' --data "$body" || true)
    echo "[railway-boot] administrator $SENDDOCK_ADMIN_EMAIL created, setup answered $code"
  else
    echo "[railway-boot] setup_required is '$need_setup', administrator left alone"
  fi
) &

exec "$@"
