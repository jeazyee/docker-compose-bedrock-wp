FROM php:8.2-fpm

# Install system dependencies including nginx and cron
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libssl-dev \
    libicu-dev \
    libmagickwand-dev \
    libonig-dev \
    zip \
    unzip \
    git \
    openssl \
    curl \
    cron \
    sudo \
    nginx \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo \
    pdo_mysql \
    gd \
    exif \
    zip \
    bcmath \
    opcache \
    intl \
    soap \
    calendar \
    sockets \
    gettext \
    && docker-php-ext-enable mysqli pdo pdo_mysql

# Install Imagick extension
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install APCu for object caching
RUN pecl install apcu \
    && docker-php-ext-enable apcu

# Install redis for object caching (optional but recommended)
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && echo "PATH=$PATH:/var/www/html/vendor/bin" >> /etc/bash.bashrc \
    && mkdir -p /var/www/.wp-cli \
    && mkdir -p /root/.wp-cli

# Create WP-CLI config for both root and www-data user
RUN echo 'path: /var/www/html/web/wp' > /root/.wp-cli/config.yml \
    && echo 'server:' >> /root/.wp-cli/config.yml \
    && echo '  docroot: /var/www/html/web' >> /root/.wp-cli/config.yml \
    && mkdir -p /var/www/.wp-cli \
    && cp /root/.wp-cli/config.yml /var/www/.wp-cli/config.yml \
    && chown -R www-data:www-data /var/www/.wp-cli

# Create a wrapper script for WP-CLI to run as www-data
RUN echo '#!/bin/bash' > /usr/local/bin/wp-user && \
    echo 'sudo -E -u www-data wp "$@"' >> /usr/local/bin/wp-user && \
    chmod +x /usr/local/bin/wp-user && \
    echo 'alias wpuser="wp-user"' >> /etc/bash.bashrc

# Configure sudo for www-data user
RUN echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure PHP settings for WordPress
RUN echo "upload_max_filesize = 64M" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 64M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_input_vars = 3000" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=4000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=2" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/opcache.ini

# Set working directory to the Bedrock project root
WORKDIR /var/www/html

# Create directory for nginx pid file
RUN mkdir -p /run/nginx

# Copy nginx configuration
COPY ./docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Configure supervisor
COPY ./docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy WordPress cron script
COPY ./docker/scripts/wp-cron.sh /usr/local/bin/wp-cron.sh
RUN chmod +x /usr/local/bin/wp-cron.sh

# Fix Git dubious ownership issue
RUN git config --global --add safe.directory /var/www/html

# Make the entrypoint script executable
COPY ./docker/scripts/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Expose port 80
EXPOSE 80
