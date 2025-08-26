#!/usr/bin/env bash
set -euo pipefail

# Preparar directorios necesarios
mkdir -p storage/framework/{cache,sessions,views} bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache || true
find storage -type d -exec chmod 775 {} + || true
chmod 775 bootstrap/cache || true

# Si hay APP_KEY y la app está instalada, limpiar y optimizar
if [[ -f artisan ]]; then
  php artisan config:clear || true
  php artisan cache:clear || true
  php artisan view:clear || true
  php artisan route:clear || true
  if [[ "${RUN_MIGRATIONS}" == "1" ]]; then
    echo "==> Intentando migraciones (RUN_MIGRATIONS=1)"
    tries=${MIGRATE_RETRIES:-5}
    delay=${MIGRATE_SLEEP:-3}
    for i in $(seq 1 "$tries"); do
      if php artisan migrate --force; then
        echo "Migraciones aplicadas"
        break
      else
        echo "Intento $i/$tries fallido; reintentando en ${delay}s"; sleep "$delay"
      fi
    done
  fi
  if [[ -n "${APP_KEY:-}" ]]; then
    php artisan optimize || true
  fi
fi

exec "$@"
