#!/bin/bash

cd /var/www/html

# Generar archivo .env si no existe
if [ ! -f .env ]; then
    cp .env.example .env
fi

# Generar clave de aplicación SOLO si no existe (regenerarla en cada
# arranque invalida sesiones y cookies cifradas → bucles de login y 419)
if ! grep -q '^APP_KEY=base64:.' .env 2>/dev/null && [ -z "$APP_KEY" ]; then
    php artisan key:generate
fi

# Migraciones opcionales en el arranque (desactivado por defecto).
# En producción se lanzan manualmente en cada despliegue.
if [ "$MIGRATE_ON_BOOT" = "true" ]; then
    php artisan migrate --force || true
fi

# Optimizar configuración para producción
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Iniciar supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
