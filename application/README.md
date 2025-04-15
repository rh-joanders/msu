This directory contains the source code for a simple PHP web application that connects to a MySQL database.

## Overview

The application is a basic visitor counter that:
1. Connects to a MySQL database
2. Creates a `visitors` table if it doesn't exist
3. Records each visit in the database
4. Displays the total number of visitors and server information

## Files

- `index.php`: The main PHP application file
- `Dockerfile`: Definition for building the application container image

## Environment Variables

The application uses the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| MYSQL_SERVICE_HOST | MySQL service hostname | mysql |
| MYSQL_USER | MySQL username | lamp_user |
| MYSQL_PASSWORD | MySQL password | lamp_password |
| MYSQL_DATABASE | MySQL database name | lamp_db |

## Docker Build

To build the container locally:

```bash
docker build -t lamp-app:latest .
```

## Local Development

For local development, you can run the application using PHP's built-in server:

```bash
php -S localhost:8080
```

Note: You'll need a MySQL database to connect to. You can adjust the connection parameters in the PHP code for local testing.
