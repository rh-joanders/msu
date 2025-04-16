# Use PHP 8.1 with Apache as the base image
FROM php:8.1-apache

# Install required PHP extensions and dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev \
    unzip \
    git \
    curl \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set Apache document root to public directory
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# Update Apache configuration
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && \
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf && \
    # Enable mod_rewrite for .htaccess support
    a2enmod rewrite

# Configure Apache to use port 8080 instead of 80 (OpenShift requirement)
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8080>/g' /etc/apache2/sites-available/000-default.conf && \
    # Add ServerName to suppress warning
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Install dependencies with Composer if composer.json exists
RUN if [ -f "composer.json" ]; then composer install --no-dev --optimize-autoloader; fi

# Create storage directories and set permissions
RUN mkdir -p storage/logs storage/cache storage/app && \
    chmod -R 777 storage

# OpenShift specific security - prepare for running as non-root
RUN chgrp -R 0 /var/www/html && \
    chmod -R g=u /var/www/html && \
    chgrp -R 0 /var/log/apache2 && \
    chmod -R g=u /var/log/apache2 && \
    chgrp -R 0 /var/run/apache2 && \
    chmod -R g=u /var/run/apache2

# Run as a non-root user (arbitrary user ID assigned by OpenShift)
USER 1001

# Expose port 8080
EXPOSE 8080

# Start Apache server in the foreground
CMD ["apache2-foreground"]