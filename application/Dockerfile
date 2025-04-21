# Use Red Hat Universal Base Image (UBI) with PHP 8.1
FROM registry.access.redhat.com/ubi9/php-81:latest

# Install MySQL extensions
USER 0
RUN yum -y install php-mysqlnd php-pdo && yum clean all

# The UBI PHP image expects content in /opt/app-root/src
# But we need to handle the /public subdirectory pattern

# Copy application files (as the default user)
USER 1001
COPY --chown=1001:0 . /opt/app-root/src/

# Create an index.php in the root that includes the actual index.php from public
RUN echo '<?php include "public/index.php"; ?>' > /opt/app-root/src/index.php && \
    # Make storage writable
    chmod -R 777 /opt/app-root/src/storage

# Apache is already configured to listen on 8080 in the base image
EXPOSE 8080

# Start Apache
CMD ["httpd", "-D", "FOREGROUND"]