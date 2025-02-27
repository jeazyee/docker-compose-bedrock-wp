# Docker Compose for Bedrock WordPress

<p align="center">
  <img src="https://cdn.roots.io/app/uploads/logo-bedrock.svg" height="100" alt="Bedrock Logo">
  <img src="https://www.docker.com/wp-content/uploads/2022/03/Moby-logo.png" height="100" alt="Docker Logo">
</p>

This repository contains Docker configuration for running a WordPress site using Roots Bedrock.

## Features

- **Zero Configuration Setup** - Run a single command to get up and running
- **Modern WordPress Stack** - Based on Bedrock by Roots
- **Docker-based** - Consistent environment across all team members
- **Performance Optimized** - Nginx with FastCGI caching and PHP-FPM
- **Development Ready** - Includes all necessary tooling and extensions
- **WP-CLI Support** - Easily manage your WordPress installation
- **Scalable Architecture** - Ready for local development and production deployment
- **Secure by Default** - Environmental configuration and proper file separation

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Git

## Complete Installation Guide

### Setup

1. Clone this repository
   ```bash
   git clone https://github.com/yourusername/docker-compose-bedrock-wp.git myproject
   cd myproject
   ```

2. Copy the example environment file:
   ```bash
   cp .env.docker-example .env
   ```

3. **Setup a local domain and environment**:
   
   Using the setup script (recommended for beginners):
   ```bash
   sudo ./docker/scripts/setup-local.sh mysite.local
   ```
   
   Or manually:
   ```bash
   # Add to your hosts file
   echo "127.0.0.1 mysite.local" | sudo tee -a /etc/hosts
   
   # Create .env file
   cp .env.example .env
   # Edit .env file with your preferred settings
   # Set APP_DOMAIN to your local domain (mysite.local)
   ```

4. Start the Docker containers:
   ```bash
   docker-compose up -d
   ```

5. **Initialize WordPress**:
   ```bash
   # Install WordPress
   ./wp core install --url=http://mysite.local --title="My Site" --admin_user=admin --admin_password=password --admin_email=admin@example.com
   
   # Optional: Install some starter plugins
   ./wp plugin install redis-cache query-monitor --activate
   ```

6. **Access your site**:
   - Frontend: [http://mysite.local](http://mysite.local)
   - WordPress Admin: [http://mysite.local/wp/wp-admin](http://mysite.local/wp/wp-admin)

## Troubleshooting

### Vendor Directory Issues

If you encounter issues with the vendor directory not being created, you can try:

```bash
# Create the vendor directory with proper permissions
docker-compose exec bedrock mkdir -p /var/www/html/vendor
docker-compose exec bedrock chown -R www-data:www-data /var/www/html/vendor

# Run composer install manually
docker-compose exec -u www-data bedrock composer install
```

### Git Permissions

If you encounter Git permission issues, you can resolve them with:

```bash
docker-compose exec bedrock git config --global --add safe.directory /var/www/html
```

### Directory Structure Explained
