# Updated Dockerfile with simplified Apache configuration
FROM registry.access.redhat.com/ubi9/php-81:latest

# Switch to root for installation tasks
USER 0

# Install required packages
RUN yum -y update && yum -y install \
    zip \
    unzip \
    git \
    libzip \
    libzip-devel \
    php-mysqlnd \
    php-pdo \
    && yum clean all

# Verify extensions are installed
RUN php -m | grep -E 'zip|mysql|pdo'

# Configure Apache to use port 8080 (OpenShift requirement)
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf && \
    echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Set the Apache document root to public directory
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

# Update Apache configuration - SIMPLIFIED APPROACH
RUN mkdir -p ${APACHE_DOCUMENT_ROOT} && \
    sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/httpd/conf/httpd.conf && \
    sed -ri -e "s!/etc/httpd/htdocs!${APACHE_DOCUMENT_ROOT}!g" /etc/httpd/conf/httpd.conf && \
    # Enable mod_rewrite for .htaccess support
    grep -q "LoadModule rewrite_module" /etc/httpd/conf.modules.d/00-base.conf || \
    echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/httpd/conf.modules.d/00-base.conf

# Write a simple config file with permissive directory settings
RUN echo 'AllowOverride All' > /etc/httpd/conf.d/document-root.conf && \
    echo 'Require all granted' >> /etc/httpd/conf.d/document-root.conf && \
    echo 'Options Indexes FollowSymLinks' >> /etc/httpd/conf.d/document-root.conf

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Install Composer (if not already installed)
RUN if ! command -v composer &> /dev/null; then \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    fi

# Install dependencies with Composer if composer.json exists
RUN if [ -f "composer.json" ]; then composer install --no-dev --optimize-autoloader; fi

# Create storage directories and set permissions
RUN mkdir -p storage/logs storage/cache storage/app && \
    chmod -R 777 storage

# OpenShift specific security - prepare for running as non-root
RUN chgrp -R 0 /var/www/html && \
    chmod -R g=u /var/www/html && \
    # Adjust for UBI9 directory structure
    chgrp -R 0 /var/log/httpd && \
    chmod -R g=u /var/log/httpd && \
    chgrp -R 0 /run/httpd && \
    chmod -R g=u /run/httpd

# Replace your current Apache configuration with this more direct approach
RUN mkdir -p ${APACHE_DOCUMENT_ROOT} && \
    echo "<VirtualHost *:8080>" > /etc/httpd/conf.d/vhost.conf && \
    echo "    DocumentRoot ${APACHE_DOCUMENT_ROOT}" >> /etc/httpd/conf.d/vhost.conf && \
    echo "    <Directory ${APACHE_DOCUMENT_ROOT}>" >> /etc/httpd/conf.d/vhost.conf && \
    echo "        AllowOverride All" >> /etc/httpd/conf.d/vhost.conf && \
    echo "        Require all granted" >> /etc/httpd/conf.d/vhost.conf && \
    echo "        Options Indexes FollowSymLinks" >> /etc/httpd/conf.d/vhost.conf && \
    echo "    </Directory>" >> /etc/httpd/conf.d/vhost.conf && \
    echo "</VirtualHost>" >> /etc/httpd/conf.d/vhost.conf

# Increase Apache logging level
RUN sed -i 's/LogLevel warn/LogLevel debug/g' /etc/httpd/conf/httpd.conf

# Add PHP error logging
RUN echo "error_reporting = E_ALL" >> /etc/php.ini && \
    echo "display_errors = On" >> /etc/php.ini && \
    echo "log_errors = On" >> /etc/php.ini && \
    echo "error_log = /var/log/httpd/php_errors.log" >> /etc/php.ini

    # Fix permissions more aggressively
RUN chmod -R 755 /var/www/html && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    chmod -R 777 /var/www/html/storage

# Create a simple index.php in the public directory if it doesn't exist
RUN if [ ! -f "${APACHE_DOCUMENT_ROOT}/index.php" ]; then \
    echo '<?php echo "LAMP Application is running. If you see this page, Apache is correctly configured."; ?>' > ${APACHE_DOCUMENT_ROOT}/index.php; \
    fi

# Switch back to non-root user (UBI default is 1001)
USER 1001

# Expose port 8080
EXPOSE 8080

# Start Apache server in the foreground
CMD ["httpd", "-D", "FOREGROUND"]