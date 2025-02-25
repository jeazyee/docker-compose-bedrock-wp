#!/bin/bash

# Check if domain argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain> (e.g., $0 test.local)"
    exit 1
fi

DOMAIN=$1
IP="127.0.0.1"

# Check OS type and modify hosts file accordingly
modify_hosts() {
    local hosts_entry="$IP $DOMAIN"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! grep -q "$DOMAIN" /etc/hosts; then
            echo "Adding hosts entry for macOS..."
            sudo bash -c "echo '$hosts_entry' >> /etc/hosts"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if ! grep -q "$DOMAIN" /etc/hosts; then
            echo "Adding hosts entry for Linux..."
            sudo bash -c "echo '$hosts_entry' >> /etc/hosts"
        fi
    else
        echo "Unsupported OS. Please add '$hosts_entry' to your hosts file manually."
        exit 1
    fi
}

# Create or update .env file
setup_env() {
    cat > .env << EOF
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

# Check if running with necessary privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo privileges for hosts file modification"
    exit 1
fi

# Execute setup steps
modify_hosts
setup_env

# Ensure docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "docker-compose not found. Please install Docker and docker-compose first."
    exit 1
fi

# Restart Docker services
echo "Restarting Docker services..."
docker-compose down
docker-compose up -d

echo "Setup completed! Your site should be available at http://$DOMAIN"
echo "Please wait a few moments for the services to fully start..."
