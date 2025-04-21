# Use Red Hat Universal Base Image (UBI) with PHP 8.1
FROM registry.access.redhat.com/ubi9/php-81:latest

# Install MySQL extensions (already included in the image, but added for clarity)
USER 0
RUN dnf -y install php-mysqlnd php-pdo && dnf clean all

# Set Apache configurations to properly find and serve application files
RUN mkdir -p /var/www/html && \
    # Add our specific DocumentRoot configuration
    echo 'DocumentRoot "/var/www/html"' > /etc/httpd/conf.d/documentroot.conf && \
    # Add index.php to DirectoryIndex directive
    echo 'DirectoryIndex index.php index.html' > /etc/httpd/conf.d/php_index.conf && \
    # Ensure /var/www/html directory has proper permissions
    chmod -R a+rwx /var/www/html && \
    # Make sure application user can read/write to the directory
    chown -R 1001:0 /var/www/html

# Copy application files into the document root
COPY --chown=1001:0 . /var/www/html/

# Make storage directory writable
RUN chmod -R 777 /var/www/html/storage && \
    # Ensure correct permissions
    chown -R 1001:0 /var/www/html

# Switch back to non-root user
USER 1001

# Expose the web port
EXPOSE 8080

# Start Apache
CMD ["httpd", "-D", "FOREGROUND"]