# Use Red Hat Universal Base Image (UBI) with PHP 8.1
FROM registry.access.redhat.com/ubi9/php-81:latest

# Switch to root for installation tasks
USER 0

# Install required packages using yum
RUN yum -y update && yum -y install \
    zip \
    unzip \
    git \
    curl \
    libzip \
    libzip-devel \
    && yum clean all

# Install PHP extensions
RUN pecl install zip && \
    echo "extension=zip.so" > /etc/php.d/zip.ini && \
    php -m | grep zip

# Install PHP MySQL extensions
RUN yum -y install mysql-devel && \
    php -m | grep -i mysql || echo "Installing MySQL extensions..." && \
    yum -y install php-mysqlnd php-pdo && \
    yum clean all

# Configure Apache to use port 8080 instead of 80 (OpenShift requirement)
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8080>/g' /etc/httpd/conf.d/ssl.conf && \
    # Add ServerName to suppress warning
    echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Set the Apache document root to public directory
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# Update Apache configuration
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/httpd/conf/httpd.conf && \
    # Enable mod_rewrite for .htaccess support
    sed -i 's/#LoadModule rewrite_module modules\/mod_rewrite.so/LoadModule rewrite_module modules\/mod_rewrite.so/g' /etc/httpd/conf/httpd.conf && \
    echo '<Directory "${APACHE_DOCUMENT_ROOT}">' >> /etc/httpd/conf/httpd.conf && \
    echo '    AllowOverride All' >> /etc/httpd/conf/httpd.conf && \
    echo '    Require all granted' >> /etc/httpd/conf/httpd.conf && \
    echo '</Directory>' >> /etc/httpd/conf/httpd.conf

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install dependencies with Composer if composer.json exists
RUN if [ -f "composer.json" ]; then composer install --no-dev --optimize-autoloader; fi

# Create storage directories and set permissions
RUN mkdir -p storage/logs storage/cache storage/app && \
    chmod -R 777 storage

# OpenShift specific security - prepare for running as non-root
RUN chgrp -R 0 /var/www/html && \
    chmod -R g=u /var/www/html && \
    chgrp -R 0 /var/log/httpd && \
    chmod -R g=u /var/log/httpd && \
    chgrp -R 0 /run/httpd && \
    chmod -R g=u /run/httpd

# Switch back to non-root user (UBI default is 1001)
USER 1001

# Expose port 8080
EXPOSE 8080

# Start Apache server in the foreground
CMD ["httpd", "-D", "FOREGROUND"]