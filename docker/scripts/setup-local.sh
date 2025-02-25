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
sleep 5

# Check if services are running
if curl -s -I "http://$DOMAIN" > /dev/null 2>&1; then
    echo "Setup completed! Your site should be available at http://$DOMAIN"
else
    echo "Warning: Site may not be accessible yet. Please check Docker logs for errors."
    echo "You can try: docker compose logs"
fi
