PHP Kickstarter Template
A minimal yet complete PHP application template designed to be a starting point for containerized PHP applications. This template follows standard PHP project conventions while maintaining simplicity.
Features

Clean directory structure following modern PHP conventions
Ready for containerization with Docker
Configurable database connection (MySQL/MariaDB)
Simple MVC architecture
Easy to understand and extend
Drop-in compatible for existing PHP applications

Directory Structure
project-root/
├── app/                    # Application core files
├── public/                 # Publicly accessible files (web root)
├── routes/                 # Route definitions
├── src/                    # Custom PHP classes
├── storage/                # Storage for logs, cache, etc.
├── tests/                  # Test files
├── vendor/                 # Composer dependencies
See each directory's README for more specific information.
Requirements

PHP 8.1 or higher
Composer (for dependency management)
Docker (for containerization)
MySQL/MariaDB (for database)

Quick Start
Local Development

Clone this repository
Configure your database connection in app/config/database.php
Start your local development environment:

bash# Using PHP's built-in server
php -S localhost:8080 -t public

# Or using Docker Compose
docker-compose up -d

Visit http://localhost:8080 in your browser

Using Docker
Build and run the application with Docker:
bash# Build the Docker image
docker build -t php-kickstarter .

# Run the container
docker run -p 8080:8080 php-kickstarter
Environment Variables
VariableDescriptionDefaultMYSQL_SERVICE_HOSTMySQL service hostnamemysqlMYSQL_USERMySQL usernamelamp_userMYSQL_PASSWORDMySQL passwordlamp_passwordMYSQL_DATABASEMySQL database namelamp_db
Deploying to OpenShift
This template is pre-configured for deployment to OpenShift:
bash# Log in to your OpenShift cluster
oc login

# Create a new project
oc new-project my-php-app

# Deploy the application
oc new-app https://github.com/your-username/php-kickstarter.git

# Expose the service
oc expose svc/php-kickstarter
Adding Your Code
To convert an existing PHP application:

Place controllers in app/controllers/
Place models in app/models/
Place views/templates in app/views/
Place static assets in public/assets/
Update routes in routes/web.php
Update database configuration in app/config/database.php

If your application follows a different structure, you can simply replace all files while maintaining the public/index.php as the entry point.
License
This project is licensed under the MIT License - see the LICENSE file for details.