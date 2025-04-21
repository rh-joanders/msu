# Use Red Hat Universal Base Image (UBI) with PHP 8.1
FROM registry.access.redhat.com/ubi9/php-81:latest

# Switch to root for installation tasks
USER 0

# Install required packages
RUN yum -y install \
    php-mysqlnd \
    php-pdo \
    && yum clean all

# Set up application files
COPY --chown=1001:0 . /opt/app-root/src/
WORKDIR /opt/app-root/src/

# Create symbolic links from the UBI expected document root to our public directory
RUN ln -sf /opt/app-root/src/public/* /opt/app-root/src/ && \
    chmod -R g+w /opt/app-root/src && \
    chmod -R 777 /opt/app-root/src/storage

# Switch back to default user
USER 1001

# Expose port 8080
EXPOSE 8080

# Start Apache
CMD ["httpd", "-D", "FOREGROUND"]