# Deploy Laravel en Koyeb con Postgres

## 1. Variables de entorno mínimas (Koyeb)
```
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
APP_URL=https://<tu-app>.koyeb.app

DB_CONNECTION=pgsql
DB_HOST=<host>
DB_PORT=5432
DB_DATABASE=<db>
DB_USERNAME=<user>
DB_PASSWORD=<password>

SESSION_DRIVER=database
QUEUE_CONNECTION=database
CACHE_STORE=database
FILESYSTEM_DISK=local
LOG_CHANNEL=stderr
```
Genera APP_KEY localmente: `php artisan key:generate --show`

## 2. Procfile
```
web: vendor/bin/heroku-php-apache2 public/
# release: php artisan migrate --force
```
Descomenta `release` si quieres migraciones automáticas (idempotentes).

## 3. Postgres
- Crear instancia (Railway, Render, Neon, Supabase, etc.)
- Habilitar SSL si el proveedor lo exige y ajustar `DB_SSLMODE=require` (agregar variable si se necesita).

## 4. Migraciones y seeds
En primera subida (si no usas release):
```
php artisan migrate --force
php artisan db:seed --force   # opcional
```

## 5. Caches de Laravel (opcional optimizar build)
```
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
```
(Se pueden ejecutar en un paso post-install o manualmente tras ajustar variables definitivas.)

## 6. Logs
Usar `LOG_CHANNEL=stderr` permite ver logs en la consola de Koyeb. Si usas stack, asegúrate de que `storage/logs` es escribible.

## 7. Sesiones / Cache / Queue
Con Postgres:
- Ejecutar migración que crea `sessions` (ya la agregaste si generaste `php artisan session:table`).
- `php artisan queue:table` y migrar si empleas jobs persistentes.

Si más adelante adoptas Redis:
```
REDIS_HOST=... (y cambia CACHE_STORE=redis, QUEUE_CONNECTION=redis, SESSION_DRIVER=redis)
```

## 8. Builds reproducibles
Asegura composer.lock committeado. Koyeb ejecutará `composer install --no-dev --prefer-dist --optimize-autoloader` (ajústalo en configuración si quieres).

## 9. Seguridad
- Nunca subas `.env`.
- Regenera APP_KEY si se filtró.
- Revisa que `APP_DEBUG=false` en producción.

## 10. Checklist rápido antes de redeploy
- [ ] APP_KEY seteado
- [ ] DB accesible desde Koyeb
- [ ] Migraciones aplicadas
- [ ] Procfile presente
- [ ] APP_URL correcto
- [ ] APP_DEBUG=false

## 11. Cambio desde SQLite
1. Actualiza variables a Postgres.
2. Ejecuta migraciones en la nueva DB.
3. Cambia drivers de sesión/cache/queue si los habías puesto en file/array.
4. Limpia caches: `php artisan optimize:clear && php artisan optimize`.

## 12. Troubleshooting
| Síntoma | Causa | Solución |
| ------- | ----- | -------- |
| 500 + "No application encryption key" | APP_KEY vacío | Generar y setear |
| 500 + SQLSTATE Connection refused | Credenciales/host DB mal | Verificar host/puerto SSL |
| 403 / No index | Falta Procfile o root mal | Asegurar `web: ... public/` |
| Session not found | Tabla sessions no creada | `php artisan session:table && migrate` |
| Cache path error | Permisos / falta carpeta | Verifica `storage/` y `bootstrap/cache/` |

---
Fin.
