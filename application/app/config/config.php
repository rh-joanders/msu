<?php
/**
 * Main Configuration File
 * 
 * Define global constants and configuration parameters here
 */

// Application environment
define('APP_ENV', getenv('APP_ENV') ?: 'development');

// Debug mode (enable in development only)
define('APP_DEBUG', APP_ENV === 'development');

// Application URL
define('APP_URL', getenv('APP_URL') ?: 'http://localhost:8080');

// Application name
define('APP_NAME', getenv('APP_NAME') ?: 'PHP Kickstarter');

// Database configuration (can be overridden in database.php)
define('DB_HOST', getenv('MYSQL_SERVICE_HOST') ?: 'mysql');
define('DB_USER', getenv('MYSQL_USER') ?: 'lamp_user');
define('DB_PASS', getenv('MYSQL_PASSWORD') ?: 'lamp_password');
define('DB_NAME', getenv('MYSQL_DATABASE') ?: 'lamp_db');

// Session configuration
define('SESSION_LIFETIME', 120); // minutes
define('SESSION_SECURE', false); // set to true in production with HTTPS

// Error reporting
if (APP_DEBUG) {
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1);
    error_reporting(E_ALL);
} else {
    ini_set('display_errors', 0);
    error_reporting(E_ALL & ~E_NOTICE & ~E_DEPRECATED & ~E_STRICT & ~E_WARNING);
}

// Time zone
date_default_timezone_set('UTC');

// Load additional configuration files if they exist
$configFiles = glob(__DIR__ . '/*.local.php');
foreach ($configFiles as $file) {
    require_once $file;
}