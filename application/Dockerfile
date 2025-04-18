# Use Red Hat Universal Base Image (UBI) with PHP 8.1
FROM registry.access.redhat.com/ubi9/php-81:latest

# Switch to root for installation tasks
USER 0

# Install required packages using yum
# Note: curl and zip extension are already included in the base image
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

# Configure Apache to use port 8080 instead of 80 (OpenShift requirement)
# This is likely already set in the UBI image, but ensuring it's configured
RUN grep -q "Listen 8080" /etc/httpd/conf/httpd.conf || sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf && \
    # Add ServerName to suppress warning
    echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Set the Apache document root to public directory
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# Update Apache configuration
RUN mkdir -p ${APACHE_DOCUMENT_ROOT} && \
    sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/httpd/conf/httpd.conf && \
    # Enable mod_rewrite for .htaccess support (should be enabled by default in UBI)
    grep -q "LoadModule rewrite_module" /etc/httpd/conf.modules.d/00-base.conf || \
    echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/httpd/conf.modules.d/00-base.conf && \
    echo '<Directory "${APACHE_DOCUMENT_ROOT}">' >> /etc/httpd/conf/httpd.conf && \
    echo '    AllowOverride All' >> /etc/httpd/conf/httpd.conf && \
    echo '    Require all granted' >> /etc/httpd/conf/httpd.conf && \
    echo '</Directory>' >> /etc/httpd/conf/httpd.conf

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

# Switch back to non-root user (UBI default is 1001)
USER 1001

# Expose port 8080
EXPOSE 8080

# Start Apache server in the foreground
CMD ["httpd", "-D", "FOREGROUND"]