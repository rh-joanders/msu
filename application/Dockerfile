# Use Red Hat Universal Base Image (UBI) with PHP 8.1
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

# Set up a symlink from the default documentroot to our application
RUN mkdir -p /opt/app-root/src/public

# Set working directory
WORKDIR /opt/app-root/src

# Copy application files to the standard UBI PHP path
COPY . /opt/app-root/src/

# Create .htaccess file to handle URL rewriting
RUN echo 'RewriteEngine On\n\
RewriteBase /\n\
RewriteCond %{REQUEST_FILENAME} !-f\n\
RewriteCond %{REQUEST_FILENAME} !-d\n\
RewriteRule ^(.*)$ index.php?/$1 [L]' > /opt/app-root/src/public/.htaccess

# Set proper permissions
RUN chgrp -R 0 /opt/app-root && \
    chmod -R g=u /opt/app-root && \
    # Ensure httpd can write to storage directory
    chmod -R 777 /opt/app-root/src/storage

# Switch back to non-root user
USER 1001

# Expose port 8080
EXPOSE 8080

# Start Apache server in the foreground
CMD ["httpd", "-D", "FOREGROUND"]