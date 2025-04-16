# Use PHP 8.1 with Apache as the base image
FROM php:8.1-apache

# Install required PHP extensions and dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev \
    unzip \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# Configure Apache to use port 8080 instead of 80
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8080>/g' /etc/apache2/sites-available/000-default.conf

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY index.php /var/www/html/

# OpenShift specific security - prepare for running as non-root
# - Change ownership to root group (which will be used in OpenShift)
# - Set appropriate permissions for logs and runtime directories
RUN chgrp -R 0 /var/www/html && \
    chmod -R g=u /var/www/html && \
    chgrp -R 0 /var/log/apache2 && \
    chmod -R g=u /var/log/apache2 && \
    chgrp -R 0 /var/run/apache2 && \
    chmod -R g=u /var/run/apache2

# Run as a non-root user (arbitrary user ID assigned by OpenShift)
USER 1001

# Expose port 8080 (Apache default is 80, but we use 8080 for OpenShift compatibility)
EXPOSE 8080

# Start Apache server in the foreground
CMD ["apache2-foreground"]