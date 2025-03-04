#!/bin/bash

# Health check for Coolify to determine if WordPress is running correctly

# Check if nginx is running
if ! pgrep nginx > /dev/null; then
    echo "❌ Nginx is not running"
    exit 1
fi

# Check if PHP-FPM is running
if ! pgrep php-fpm > /dev/null; then
    echo "❌ PHP-FPM is not running"
    exit 1
fi

# Check if the WordPress site is accessible
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost/health-check | grep -q "200"; then
    echo "❌ WordPress is not accessible"
    exit 1
fi

# All checks passed
echo "✅ WordPress is running correctly"
exit 0
