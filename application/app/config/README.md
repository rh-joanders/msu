# Configuration Directory

This directory contains the application configuration files.

## Files

- `config.php` - Main configuration file with application settings
- `database.php` - Database connection configuration
- `app.php` - Application-specific configuration
- `mail.php` - Email configuration (if needed)
- `cache.php` - Cache configuration (if needed)
- `session.php` - Session configuration (if needed)

## Local Configuration

You can create local configuration files that override the default settings. These files should be named with the `.local.php` suffix and will be loaded automatically if they exist. For example:

- `database.local.php` - Local database configuration
- `app.local.php` - Local application configuration

Local configuration files are ignored by Git to prevent sensitive information from being committed.