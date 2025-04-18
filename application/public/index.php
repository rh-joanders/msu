<?php
/**
 * PHP Kickstarter Template
 * 
 * This is the main entry point for the application.
 * All requests are routed through this file.
 */

// Define the application root directory
define('APP_ROOT', dirname(__DIR__));

// Load the composer autoloader if it exists
if (file_exists(APP_ROOT . '/vendor/autoload.php')) {
    require APP_ROOT . '/vendor/autoload.php';
}

// Load configuration if exists
if (file_exists(APP_ROOT . '/app/config/config.php')) {
    require_once APP_ROOT . '/app/config/config.php';
} else {
    // Define basic constants if config file doesn't exist
    define('APP_ENV', getenv('APP_ENV') ?: 'development');
    define('APP_DEBUG', true);
}

// Load database connection if exists
if (file_exists(APP_ROOT . '/app/config/database.php')) {
    require_once APP_ROOT . '/app/config/database.php';
}

// Load the router if exists
if (file_exists(APP_ROOT . '/routes/web.php')) {
    require_once APP_ROOT . '/routes/web.php';
}

// Initialize the application (only if the class exists)
if (class_exists('\\App\\Core\\Application')) {
    $app = new \App\Core\Application();
    
    // Run the application
    $app->run();
}

// If routes aren't defined or no matching route found, show a welcome page
if (!defined('ROUTE_MATCHED')) {
    // Database connection parameters - from environment variables with fallbacks
    $servername = getenv('MYSQL_SERVICE_HOST') ?: "mysql";
    $username = getenv('MYSQL_USER') ?: "lamp_user";
    $password = getenv('MYSQL_PASSWORD') ?: "lamp_password";
    $dbname = getenv('MYSQL_DATABASE') ?: "lamp_db";

    // Connection status variables
    $connection_status = "Not attempted";
    $connection_error = "";
    $db_version = "";
    $tables = [];

    // Try to connect to MySQL with detailed error reporting
    try {
        // Create connection
        $conn = new mysqli($servername, $username, $password, $dbname);

        // Check connection
        if ($conn->connect_error) {
            $connection_status = "Failed";
            $connection_error = $conn->connect_error;
            throw new Exception("Connection failed: " . $conn->connect_error);
        }
        
        // Connection successful - get MySQL version
        $result = $conn->query("SELECT VERSION() as version");
        if ($result && $row = $result->fetch_assoc()) {
            $db_version = $row['version'];
        }
        
        $connection_status = "Success";
        
        // Get list of tables to verify database structure
        $table_result = $conn->query("SHOW TABLES");
        if ($table_result) {
            while ($table_row = $table_result->fetch_array(MYSQLI_NUM)) {
                $tables[] = $table_row[0];
            }
        }

        // Close the database connection
        $conn->close();
        
    } catch (Exception $e) {
        // Handle exception
        if ($connection_status !== "Failed") {
            $connection_status = "Error";
            $connection_error = $e->getMessage();
        }
    }
    
    // Include the welcome template if it exists
    if (file_exists(APP_ROOT . '/app/views/welcome.php')) {
        include APP_ROOT . '/app/views/welcome.php';
    } else {
        // Simple fallback if welcome view doesn't exist
        echo "<h1>PHP Kickstarter Template</h1>";
        echo "<p>Welcome to your new PHP application!</p>";
        echo "<p>Connection status: " . $connection_status . "</p>";
        if ($connection_status === "Success") {
            echo "<p>MySQL version: " . $db_version . "</p>";
            echo "<p>Tables in database: " . implode(", ", $tables) . "</p>";
        } else {
            echo "<p>Connection error: " . $connection_error . "</p>";
        }
    }
}