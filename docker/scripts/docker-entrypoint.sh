#!/bin/bash
set -e

# Wait for database
wait_for_db() {
    echo "Waiting for database connection..."
    max_tries=30
    tries=0
    while ! mysql -h db -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
        tries=$((tries + 1))
        if [ $tries -gt $max_tries ]; then
            echo "Error: Could not connect to database after $max_tries attempts"
            exit 1
        fi
        echo "Waiting for database... attempt $tries/$max_tries"
        sleep 2
    done
    echo "Database connection established"
}

# Install composer dependencies if they're not installed
if [ ! -d /var/www/html/vendor ]; then
    composer install --working-dir=/var/www/html
fi

# Ensure uploads directory is writable
if [ -d /var/www/html/web/app/uploads ]; then
    chown -R www-data:www-data /var/www/html/web/app/uploads
    chmod -R 775 /var/www/html/web/app/uploads
fi

# Wait for database before starting
wait_for_db

exec "$@"
