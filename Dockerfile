# Etapa 1: dependencias Composer
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction

# Etapa 2: imagen de aplicación
FROM node:20 AS frontend
WORKDIR /app
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi
COPY resources ./resources
COPY vite.config.js ./
COPY public ./public
RUN npm run build || echo "(WARN) Falló build de assets; verifica dependencias"

FROM php:8.2-apache

# Instalar extensiones necesarias (pgsql, zip, etc.)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git libpq-dev libzip-dev unzip \
    && docker-php-ext-install pdo pdo_pgsql zip \
    && rm -rf /var/lib/apt/lists/*

# Configurar Apache DocumentRoot a public/
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf \
    && a2enmod rewrite

WORKDIR /var/www/html

# Copiar aplicación (sin vendor) y luego vendor
COPY . /var/www/html
COPY --from=vendor /app/vendor /var/www/html/vendor
COPY --from=frontend /app/public/build /var/www/html/public/build

# Crear y asegurar rutas de cache/almacenamiento
RUN set -eux; \
    mkdir -p storage/framework/{cache,sessions,views} \
    && mkdir -p bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && find storage -type d -exec chmod 775 {} + \
    && chmod 775 bootstrap/cache

# Copiar script de arranque
COPY docker/start.sh /start.sh
RUN chmod +x /start.sh

# Variables opcionales
ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    RUN_MIGRATIONS=0 \
    MIGRATE_RETRIES=5 \
    MIGRATE_SLEEP=3

USER www-data

# Exponer puerto Apache
EXPOSE 80

# Entrada: script que prepara caches si variables están listas
ENTRYPOINT ["/start.sh"]
CMD ["apache2-foreground"]
