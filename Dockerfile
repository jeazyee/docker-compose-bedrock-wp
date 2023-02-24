FROM php:8.1-fpm

RUN docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable mysqli pdo pdo_mysql

# Install stuff to make composer work
RUN apt-get update && apt-get install -y zip unzip git openssl

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory to the Bedrock project root
WORKDIR /var/www/html

## Copy the Bedrock files into the container
COPY . /var/www/html

RUN chmod +x /var/www/html/dotenv-generator.sh

RUN /var/www/html/dotenv-generator.sh

# Install the project dependencies with Composer
RUN composer install --working-dir=/var/www/html

# Set the ownership of the Bedrock files to the www-data user
RUN chown -R www-data:www-data /var/www/html && find /var/www/html/ -type f -exec chmod 644 {} \; && find /var/www/html/ -type d -exec chmod 755 {} \;

# Set the entrypoint to run the PHP-FPM process
CMD ["php-fpm"]
