#!/usr/bin/env bash
# Actualiza y (re)despliega AgroApp con el override del homelab.
# Uso: ./deploy.sh            (pull + build + up)
#      ./deploy.sh --no-pull  (sin actualizar el repo de la app)
set -euo pipefail

APP_DIR="${APP_DIR:-$HOME/agroapp}"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [[ "${1:-}" != "--no-pull" ]]; then
  git -C "$APP_DIR" pull --ff-only
fi

docker compose \
  -f "$APP_DIR/docker-compose.yml" \
  -f "$HERE/docker-compose.homelab.yml" \
  --env-file "$HERE/.env" \
  up -d --build
