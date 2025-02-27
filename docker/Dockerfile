FROM php:8.2-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    git \
    curl \
    zip \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libonig-dev \
    libzip-dev \
    libicu-dev \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo \
    pdo_mysql \
    gd \
    opcache \
    intl \
    zip \
    exif

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && mkdir -p /var/www/.wp-cli/cache \
    && chown -R www-data:www-data /var/www/.wp-cli

# Create symlink for www-data to use WP-CLI
RUN ln -s /usr/local/bin/wp /usr/local/bin/wp-user

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Configure PHP
COPY ./docker/php/uploads.ini /usr/local/etc/php/conf.d/uploads.ini

# Create directory for PHP-FPM socket
RUN mkdir -p /var/run/php-fpm

# Set working directory
WORKDIR /var/www/html

# Copy entry point script
COPY ./docker/scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
