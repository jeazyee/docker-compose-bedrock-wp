#!/bin/bash
set -e

# Install composer dependencies if they're not installed
if [ ! -d /var/www/html/vendor ]; then
    composer install --working-dir=/var/www/html
fi

# Ensure uploads directory is writable
if [ -d /var/www/html/web/app/uploads ]; then
    chown -R www-data:www-data /var/www/html/web/app/uploads
    chmod -R 775 /var/www/html/web/app/uploads
fi

exec "$@"
