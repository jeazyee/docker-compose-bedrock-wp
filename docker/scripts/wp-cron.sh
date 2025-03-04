#!/bin/bash

# Script to execute WordPress cron via WP-CLI
cd /var/www/html

# Log with timestamp
LOGFILE="/var/www/html/wp-cron.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$TIMESTAMP] Running WordPress cron..." >> "$LOGFILE" 2>&1

# Run WP-CLI cron as www-data user
sudo -E -u www-data wp cron event run --due-now >> "$LOGFILE" 2>&1

# Execute any additional commands that might be defined by Coolify environment variables
if [ -n "$WP_CRON_CUSTOM_COMMAND" ]; then
    echo "[$TIMESTAMP] Running custom command: $WP_CRON_CUSTOM_COMMAND" >> "$LOGFILE" 2>&1
    sudo -E -u www-data bash -c "$WP_CRON_CUSTOM_COMMAND" >> "$LOGFILE" 2>&1
fi

# Log completion
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$TIMESTAMP] Cron execution completed" >> "$LOGFILE" 2>&1
