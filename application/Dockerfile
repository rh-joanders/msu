# Base image with PHP 8.1 on UBI 9
FROM registry.access.redhat.com/ubi9/php-81:latest

# Switch to root for installation and configuration
USER 0

# Install required packages in a single layer
RUN dnf -y update && dnf -y install \
    php-mysqlnd \
    php-pdo \
    zip \
    unzip \
    git \
    && dnf clean all

# Configure Apache for OpenShift
# - Set port to 8080
# - Add ServerName to avoid warnings
# - Configure document root to be /var/www/html/public
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf && \
    echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf && \
    mkdir -p /var/www/html/public

# Create a simple VirtualHost configuration for port 8080
RUN echo '<VirtualHost *:8080>' > /etc/httpd/conf.d/000-default.conf && \
    echo '    DocumentRoot /var/www/html/public' >> /etc/httpd/conf.d/000-default.conf && \
    echo '    <Directory /var/www/html/public>' >> /etc/httpd/conf.d/000-default.conf && \
    echo '        AllowOverride All' >> /etc/httpd/conf.d/000-default.conf && \
    echo '        Require all granted' >> /etc/httpd/conf.d/000-default.conf && \
    echo '        Options Indexes FollowSymLinks' >> /etc/httpd/conf.d/000-default.conf && \
    echo '    </Directory>' >> /etc/httpd/conf.d/000-default.conf && \
    echo '</VirtualHost>' >> /etc/httpd/conf.d/000-default.conf

# Remove or disable SSL configuration to avoid warnings
RUN if [ -f "/etc/httpd/conf.d/ssl.conf" ]; then \
    mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.disabled; \
    fi

# Copy application files
COPY . /var/www/html/

# Create a test index file if one doesn't exist
#RUN if [ ! -f "/var/www/html/public/index.php" ]; then \
#    echo '<?php' > /var/www/html/public/index.php && \
#    echo 'echo "<h1>LAMP Stack on OpenShift</h1>";' >> /var/www/html/public/index.php && \
#    echo 'echo "<p>Your PHP version is: " . phpversion() . "</p>";' >> /var/www/html/public/index.php && \
#    echo 'echo "<h2>Database Connection Test:</h2>";' >> /var/www/html/public/index.php && \
#    echo 'try {' >> /var/www/html/public/index.php && \
#    echo '    $host = getenv("MYSQL_SERVICE_HOST") ?: "mysql";' >> /var/www/html/public/index.php && \
#    echo '    $user = getenv("MYSQL_USER") ?: "lamp_user";' >> /var/www/html/public/index.php && \
#    echo '    $pass = getenv("MYSQL_PASSWORD") ?: "lamp_password";' >> /var/www/html/public/index.php && \
#    echo '    $dbname = getenv("MYSQL_DATABASE") ?: "lamp_db";' >> /var/www/html/public/index.php && \
#    echo '    $conn = new PDO("mysql:host=$host;dbname=$dbname", $user, $pass);' >> /var/www/html/public/index.php && \
#    echo '    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);' >> /var/www/html/public/index.php && \
#    echo '    echo "<p style=\"color:green\">Connected successfully to MySQL!</p>";' >> /var/www/html/public/index.php && \
#    echo '    $stmt = $conn->query("SELECT VERSION() as version");' >> /var/www/html/public/index.php && \
#    echo '    $row = $stmt->fetch(PDO::FETCH_ASSOC);' >> /var/www/html/public/index.php && \
#    echo '    echo "<p>MySQL Version: " . $row["version"] . "</p>";' >> /var/www/html/public/index.php && \
#    echo '} catch(PDOException $e) {' >> /var/www/html/public/index.php && \
#    echo '    echo "<p style=\"color:red\">Connection failed: " . $e->getMessage() . "</p>";' >> /var/www/html/public/index.php && \
#    echo '}' >> /var/www/html/public/index.php && \
#    echo '?>' >> /var/www/html/public/index.php; \
#    fi

# Create storage directories if they don't exist
RUN mkdir -p /var/www/html/storage/logs /var/www/html/storage/cache /var/www/html/storage/app && \
    chmod -R 777 /var/www/html/storage

# Set appropriate permissions for OpenShift
RUN chgrp -R 0 /var/www/html && \
    chmod -R g=u /var/www/html && \
    chmod -R 777 /var/www/html/storage && \
    # Ensure logs are writable
    chgrp -R 0 /var/log/httpd && \
    chmod -R g=u /var/log/httpd && \
    chgrp -R 0 /run/httpd && \
    chmod -R g=u /run/httpd

# Switch back to non-root user for security
USER 1001

# Expose port 8080
EXPOSE 8080

# Start Apache
CMD ["httpd", "-D", "FOREGROUND"]