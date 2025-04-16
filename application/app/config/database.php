<?php
/**
 * Database Configuration
 * 
 * This file handles database connections and provides
 * helper functions for database operations.
 */

// Use environment variables or fallback to defaults from config.php
$dbHost = defined('DB_HOST') ? DB_HOST : getenv('MYSQL_SERVICE_HOST') ?: 'mysql';
$dbUser = defined('DB_USER') ? DB_USER : getenv('MYSQL_USER') ?: 'lamp_user';
$dbPass = defined('DB_PASS') ? DB_PASS : getenv('MYSQL_PASSWORD') ?: 'lamp_password';
$dbName = defined('DB_NAME') ? DB_NAME : getenv('MYSQL_DATABASE') ?: 'lamp_db';

/**
 * Get mysqli database connection
 * 
 * @return mysqli A new database connection
 */
function getDbConnection() {
    global $dbHost, $dbUser, $dbPass, $dbName;
    
    $conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
    
    if ($conn->connect_error) {
        $errorMsg = "Connection failed: " . $conn->connect_error;
        error_log($errorMsg);
        
        if (defined('APP_DEBUG') && APP_DEBUG) {
            throw new Exception($errorMsg);
        } else {
            throw new Exception("Database connection error occurred. Check the logs for details.");
        }
    }
    
    return $conn;
}

/**
 * Get PDO database connection
 * 
 * @return PDO A new PDO database connection
 */
function getPdoConnection() {
    global $dbHost, $dbUser, $dbPass, $dbName;
    
    try {
        $dsn = "mysql:host={$dbHost};dbname={$dbName};charset=utf8mb4";
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];
        
        return new PDO($dsn, $dbUser, $dbPass, $options);
    } catch (PDOException $e) {
        $errorMsg = "PDO Connection failed: " . $e->getMessage();
        error_log($errorMsg);
        
        if (defined('APP_DEBUG') && APP_DEBUG) {
            throw new PDOException($errorMsg);
        } else {
            throw new PDOException("Database connection error occurred. Check the logs for details.");
        }
    }
}