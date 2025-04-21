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

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Create the default DocumentRoot and link our application files
RUN mkdir -p /etc/httpd/htdocs && \
    ln -sf /var/www/html/public/* /etc/httpd/htdocs/ && \
    # Set proper permissions
    chgrp -R 0 /var/www/html /etc/httpd/htdocs && \
    chmod -R g=u /var/www/html /etc/httpd/htdocs && \
    # Ensure httpd can write to storage directory
    chmod -R 777 /var/www/html/storage

# Switch back to non-root user
USER 1001

# Expose port 8080
EXPOSE 8080

# Start Apache server in the foreground
CMD ["httpd", "-D", "FOREGROUND"]