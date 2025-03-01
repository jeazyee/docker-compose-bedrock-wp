#!/bin/bash

# Script to execute WordPress cron via WP-CLI
cd /var/www/html

# Log with timestamp
LOGFILE="/var/www/html/wp-cron.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$TIMESTAMP] Running WordPress cron..." >> "$LOGFILE" 2>&1

# Run WP-CLI cron as www-data user
sudo -E -u www-data wp cron event run --due-now >> "$LOGFILE" 2>&1

# Log completion
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$TIMESTAMP] Cron execution completed" >> "$LOGFILE" 2>&1
