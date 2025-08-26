#!/usr/bin/env bash
set -euo pipefail

# Crear paths requeridos para evitar "valid cache path" y sesiones
mkdir -p storage/framework/{cache,sessions,views} bootstrap/cache
chmod -R 775 storage/framework bootstrap/cache || true

# Si falta APP_KEY tratar de generarla (solo si writable y no en prod estricto)
if [[ -f artisan && -z "${APP_KEY:-}" ]]; then
  php artisan key:generate --force || true
fi

# Limpiar caches inconsistentes
php artisan config:clear || true
php artisan cache:clear || true
php artisan route:clear || true
php artisan view:clear || true

# Migraciones opcionales (habilitar con MIGRATE_ON_BOOT=1)
if [[ "${MIGRATE_ON_BOOT:-0}" == "1" ]]; then
  echo "==> Ejecutando migraciones en arranque (Koyeb)"
  php artisan migrate --force || true
fi

# Optimizar si hay clave
if [[ -n "${APP_KEY:-}" ]]; then
  php artisan optimize || true
fi

# Iniciar Apache (buildpack heroku-php)
exec vendor/bin/heroku-php-apache2 public/
