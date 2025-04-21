# Use Red Hat Universal Base Image (UBI) with PHP 8.1
FROM registry.access.redhat.com/ubi9/php-81:latest

# Switch to root for installation tasks
USER 0

# Install required packages using yum
RUN yum -y update && yum -y install \
    zip \
    unzip \
    git \
    libzip \
    libzip-devel \
    php-mysqlnd \
    php-pdo \
    && yum clean all

# Configure Apache to use port 8080 and set proper document root
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf && \
    echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf && \
    sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/var/www/html/public"|g' /etc/httpd/conf/httpd.conf && \
    sed -i 's|<Directory "/var/www/html">|<Directory "/var/www/html/public">|g' /etc/httpd/conf/httpd.conf

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Create public directory if it doesn't exist
RUN mkdir -p /var/www/html/public && \
    # If public directory is empty, copy index.php to it
    if [ ! -f /var/www/html/public/index.php ]; then \
        echo '<?php phpinfo(); ?>' > /var/www/html/public/index.php; \
    fi

# Create storage directories and set permissions
RUN mkdir -p storage/logs storage/cache storage/app && \
    chmod -R 777 storage && \
    # Set proper permissions for Apache
    chgrp -R 0 /var/www/html && \
    chmod -R g=u /var/www/html && \
    # Fix SELinux contexts if needed
    chcon -R -t httpd_sys_content_t /var/www/html || true

# Switch back to non-root user
USER 1001

# Expose port 8080
EXPOSE 8080

# Start Apache server in the foreground
CMD ["httpd", "-D", "FOREGROUND"]