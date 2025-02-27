# Docker Bedrock - WordPress Development Environment

<p align="center">
  <img src="https://cdn.roots.io/app/uploads/logo-bedrock.svg" height="100" alt="Bedrock Logo">
  <img src="https://www.docker.com/wp-content/uploads/2022/03/Moby-logo.png" height="100" alt="Docker Logo">
</p>

A complete, ready-to-use Docker environment for [Bedrock](https://roots.io/bedrock/) WordPress development. This project combines the modern WordPress stack of Bedrock with Docker to create a powerful, consistent, and easily deployable development environment.

## Features

- **Zero Configuration Setup** - Run a single command to get up and running
- **Modern WordPress Stack** - Based on Bedrock by Roots
- **Docker-based** - Consistent environment across all team members
- **Performance Optimized** - Nginx with FastCGI caching and PHP-FPM
- **Development Ready** - Includes all necessary tooling and extensions
- **WP-CLI Support** - Easily manage your WordPress installation
- **Scalable Architecture** - Ready for local development and production deployment
- **Secure by Default** - Environmental configuration and proper file separation

## Requirements

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/) (included with Docker Desktop)
- Git (for version control)

## Complete Installation Guide

### Initial Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/docker-compose-bedrock-wp.git myproject
   cd myproject
   ```

2. **Setup a local domain and environment**:
   
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

3. **Start the Docker environment**:
   ```bash
   docker compose up -d
   ```

4. **Initialize WordPress**:
   ```bash
   # Install WordPress
   ./wp core install --url=http://mysite.local --title="My Site" --admin_user=admin --admin_password=password --admin_email=admin@example.com
   
   # Optional: Install some starter plugins
   ./wp plugin install redis-cache query-monitor --activate
   ```

5. **Access your site**:
   - Frontend: [http://mysite.local](http://mysite.local)
   - WordPress Admin: [http://mysite.local/wp/wp-admin](http://mysite.local/wp/wp-admin)

### Directory Structure Explained
