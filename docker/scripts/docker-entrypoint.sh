#!/bin/bash
set -e

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

# Setup WordPress cron job
setup_wp_cron() {
    # Make sure the cron script is executable
    chmod +x /usr/local/bin/wp-cron.sh
    
    # Create a crontab file
    echo "*/5 * * * * /usr/local/bin/wp-cron.sh" > /etc/cron.d/wp-cron
    chmod 0644 /etc/cron.d/wp-cron
    
    # Start cron service
    service cron start
    echo "WordPress cron service started"
}

# Install WordPress using WP-CLI (minimal setup)
install_wordpress() {
    # Check if WordPress is already installed
    if ! sudo -E -u www-data wp core is-installed; then
        echo "WordPress is not installed. Setting up a new WordPress installation..."
        
        # Check for required environment variables
        if [ -z "$WP_ADMIN_PASSWORD" ]; then
            echo "Error: WP_ADMIN_PASSWORD environment variable is required"
            return 1
        fi
        
        # Set default values
        WP_ADMIN_USER=${WP_ADMIN_USER:-admin}
        WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-admin@example.com}
        WP_TITLE=${WP_TITLE:-"WordPress Site"}
        
        # Core install
        echo "Installing WordPress at URL: $WP_HOME"
        sudo -E -u www-data wp core install \
            --url="$WP_HOME" \
            --title="$WP_TITLE" \
            --admin_user="$WP_ADMIN_USER" \
            --admin_password="$WP_ADMIN_PASSWORD" \
            --admin_email="$WP_ADMIN_EMAIL" \
            --skip-email
            
        echo "WordPress installed successfully!"
        
        # Update permalink structure
        sudo -E -u www-data wp rewrite structure '/%postname%/' --url="$WP_HOME"
        
        # Delete the default "Hello World" post
        echo "Removing default content..."
        sudo -E -u www-data wp post delete 1 --force --url="$WP_HOME"
        
        # Delete the sample page
        sudo -E -u www-data wp post delete 2 --force --url="$WP_HOME"
        
        echo "Installation complete! You can login at ${WP_HOME}/wp/wp-admin/"
    else
        echo "WordPress is already installed."
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
    
    # Setup WordPress cron
    setup_wp_cron
    
    # Install WordPress if it's not installed
    if [ "${WP_AUTO_INSTALL:-false}" = "true" ]; then
        install_wordpress
    fi
    
    # Fix recovery_mode_clean_expired_keys event if that was causing problems
    if [ "${WP_FIX_RECOVERY_EVENT:-false}" = "true" ]; then
        echo "Fixing recovery_mode_clean_expired_keys event..."
        sudo -E -u www-data wp cron event unschedule recovery_mode_clean_expired_keys
        sudo -E -u www-data wp cron event schedule recovery_mode_clean_expired_keys now hourly
        echo "Recovery mode event fixed."
    fi
    
    >&2 echo "Starting PHP-FPM server..."
fi

# Pass control to the CMD
exec "$@"
