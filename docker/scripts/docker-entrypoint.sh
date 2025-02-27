#!/bin/bash
set -e

# Make sure Git trusts the directory for all users
git config --system --add safe.directory /var/www/html
git config --global --add safe.directory /var/www/html

# Ensure www-data can use Git
if [ ! -d /var/www/.config/git ]; then
    mkdir -p /var/www/.config/git
    echo "[safe]" > /var/www/.config/git/config
    echo "    directory = /var/www/html" >> /var/www/.config/git/config
    chown -R www-data:www-data /var/www/.config
fi

# Test Git as www-data to ensure it works
sudo -u www-data git config --list > /dev/null || {
    echo "Warning: Git is still having permission issues"
    # Fallback to force Git to work with this directory
    git config --global --add safe.directory '*'
    sudo -u www-data git config --global --add safe.directory '*'
}

# Add hostname entries for internal network resolution
echo "127.0.0.1 localhost" >> /etc/hosts
echo "$(getent hosts nginx | awk '{ print $1 }') ${APP_DOMAIN}" >> /etc/hosts

# Ensure proper directory permissions for Composer
echo "Setting up directory permissions..."
mkdir -p /var/www/html/vendor
chown -R www-data:www-data /var/www/html

# Run composer install if needed - with extra debug output
if [ ! -d /var/www/html/vendor/composer ]; then
    echo "Vendor directory empty or incomplete. Running composer install..."
    ls -la /var/www/html/
    
    # Create directories that Composer needs with proper permissions
    mkdir -p /var/www/html/vendor
    chown -R www-data:www-data /var/www/html/vendor
    
    # Run Composer install as www-data with debug output
    echo "Running composer as www-data..."
    sudo -u www-data bash -c "cd /var/www/html && composer install -v"
    
    # Verify installation result
    if [ $? -ne 0 ]; then
        echo "Composer install failed. Trying with different permissions..."
        # Fallback approach with more permissive settings
        chmod -R 777 /var/www/html/vendor
        sudo -u www-data bash -c "cd /var/www/html && composer install -v"
    fi
    
    echo "Composer install completed. Directory listing:"
    ls -la /var/www/html/vendor/
fi

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
