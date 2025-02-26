#!/bin/bash

# Check if domain argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain> (e.g., $0 test.local)"
    exit 1
fi

DOMAIN=$1
IP="127.0.0.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Check if running with necessary privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo privileges for hosts file modification"
    exit 1
fi

# Check OS type and modify hosts file accordingly
modify_hosts() {
    local hosts_entry="$IP $DOMAIN"
    
    if ! grep -q "$DOMAIN" /etc/hosts; then
        echo "Adding hosts entry..."
        echo "$hosts_entry" >> /etc/hosts
    else
        echo "Host entry already exists"
    fi
}

# Create or update .env file
setup_env() {
    echo "Creating .env file..."
    cat > "$PROJECT_ROOT/.env" << EOF
APP_ENV=development
APP_DEBUG=true
APP_URL=http://$DOMAIN
APP_DOMAIN=$DOMAIN
DB_NAME=bedrock
DB_USER=user
DB_PASSWORD=password
DB_ROOT_PASSWORD=root
AUTH_KEY=$(openssl rand -hex 64)
SECURE_AUTH_KEY=$(openssl rand -hex 64)
LOGGED_IN_KEY=$(openssl rand -hex 64)
NONCE_KEY=$(openssl rand -hex 64)
AUTH_SALT=$(openssl rand -hex 64)
SECURE_AUTH_SALT=$(openssl rand -hex 64)
LOGGED_IN_SALT=$(openssl rand -hex 64)
NONCE_SALT=$(openssl rand -hex 64)
EOF
}

# Main setup process
echo "Setting up local development environment for $DOMAIN..."

# Execute setup steps
modify_hosts
setup_env

# Ensure docker-compose is available
if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo "docker compose not found. Please install Docker and docker compose first."
    exit 1
fi

# Restart Docker services
echo "Restarting Docker services..."
cd "$PROJECT_ROOT" || exit 1

# Try both docker compose and docker-compose commands
if command -v docker compose &> /dev/null; then
    docker compose down
    docker compose up -d
else
    docker-compose down
    docker-compose up -d
fi

# Wait for services to start
echo "Waiting for services to start..."
sleep 10  # Increased from 5 to 10 seconds

# Enhanced health check
MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -I "http://$DOMAIN" > /dev/null 2>&1; then
        echo "Setup completed! Your site should be available at http://$DOMAIN"
        echo "Testing REST API access..."
        if curl -s -I "http://$DOMAIN/wp-json/" > /dev/null 2>&1; then
            echo "REST API is accessible"
            exit 0
        else
            echo "REST API might not be accessible. Please check your WordPress configuration"
        fi
        break
    else
        echo "Waiting for service to become available... (Attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
        sleep 5
        RETRY_COUNT=$((RETRY_COUNT+1))
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Warning: Site may not be accessible yet. Please check Docker logs for errors."
    echo "You can try: docker compose logs"
fi
