#!/bin/bash
set -e

# Configure Git to trust the /var/www/html directory
git config --global --add safe.directory /var/www/html

# Add hostname entries for internal network resolution
echo "127.0.0.1 localhost" >> /etc/hosts
echo "$(getent hosts nginx | awk '{ print $1 }') ${APP_DOMAIN}" >> /etc/hosts

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

# Setup WP-CLI environment variables for Bedrock
setup_wp_cli() {
    # Set up Bedrock-specific environment variables for WP-CLI
    export WP_CLI_CONFIG_PATH=/var/www/.wp-cli/config.yml
    
    # Setup wp-cli.yml in project root if it doesn't exist
    if [ ! -f /var/www/html/wp-cli.yml ]; then
        echo "Creating wp-cli.yml for Bedrock..."
        cat > /var/www/html/wp-cli.yml << EOF
path: web/wp
url: ${WP_HOME}
EOF
        chown www-data:www-data /var/www/html/wp-cli.yml
    fi
}

# Install composer dependencies if they're not installed
if [ ! -d /var/www/html/vendor ]; then
    sudo -u www-data composer install --working-dir=/var/www/html
fi

# Ensure uploads directory exists and is writable
if [ ! -d /var/www/html/web/app/uploads ]; then
    mkdir -p /var/www/html/web/app/uploads
fi
chown -R www-data:www-data /var/www/html/web/app/uploads
chmod -R 775 /var/www/html/web/app/uploads

# Setup WP-CLI for Bedrock
setup_wp_cli

# If the first argument is "wp"
if [ "$1" = "wp" ]; then
    # Wait for database to be ready
    wait_for_db
    shift
    # Run WP-CLI as www-data user
    exec sudo -E -u www-data wp "$@"
# If the first argument is "wp-user" (already runs as www-data)
elif [ "$1" = "wp-user" ]; then
    # Wait for database to be ready
    wait_for_db
    shift
    exec wp-user "$@"
# If the first argument is "php-fpm" 
elif [ "${1#-}" = "php-fpm" ]; then
    # Wait for database to be ready
    wait_for_db
    
    >&2 echo "Starting PHP-FPM server..."
fi

# Pass control to the CMD
exec "$@"
