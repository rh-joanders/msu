<?php
namespace App\Core;

/**
 * Application Class
 * 
 * Main application bootstrap class that initializes
 * the application environment and handles requests.
 */
class Application
{
    /**
     * Application instance (singleton)
     */
    private static $instance = null;
    
    /**
     * Configuration settings
     */
    private $config = [];
    
    /**
     * Constructor
     */
    public function __construct()
    {
        // Ensure singleton pattern
        if (self::$instance !== null) {
            return self::$instance;
        }
        
        self::$instance = $this;
        
        // Initialize application
        $this->init();
    }
    
    /**
     * Initialize the application
     */
    private function init()
    {
        // Start session if not already started
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        
        // Load configuration
        $this->loadConfig();
        
        // Set up error handling
        $this->setupErrorHandling();
    }
    
    /**
     * Load application configuration
     */
    private function loadConfig()
    {
        // Load configurations from constants
        if (defined('APP_NAME')) $this->config['app_name'] = APP_NAME;
        if (defined('APP_ENV')) $this->config['environment'] = APP_ENV;
        if (defined('APP_DEBUG')) $this->config['debug'] = APP_DEBUG;
        if (defined('APP_URL')) $this->config['url'] = APP_URL;
    }
    
    /**
     * Set up error handling
     */
    private function setupErrorHandling()
    {
        // Custom error handler
        set_error_handler(function($level, $message, $file, $line) {
            if (error_reporting() & $level) {
                throw new \ErrorException($message, 0, $level, $file, $line);
            }
        });
        
        // Custom exception handler
        set_exception_handler(function($exception) {
            $this->handleException($exception);
        });
    }
    
    /**
     * Handle an uncaught exception
     */
    private function handleException($exception)
    {
        // Log the exception
        error_log($exception);
        
        // In debug mode, display the error
        if ($this->config['debug'] ?? false) {
            echo '<h1>Application Error</h1>';
            echo '<p>An error occurred in the application.</p>';
            echo '<p><strong>Message:</strong> ' . htmlspecialchars($exception->getMessage()) . '</p>';
            echo '<p><strong>File:</strong> ' . htmlspecialchars($exception->getFile()) . ' on line ' . $exception->getLine() . '</p>';
            echo '<h2>Stack Trace</h2>';
            echo '<pre>' . htmlspecialchars($exception->getTraceAsString()) . '</pre>';
        } else {
            // In production, show a friendly message
            include APP_ROOT . '/app/views/errors/500.php';
        }
        
        exit(1);
    }
    
    /**
     * Run the application
     */
    public function run()
    {
        // Application is now running
        // Any additional initialization can be done here
        
        // For example, dispatch to controller based on route
        // This is handled by the router in routes/web.php
    }
    
    /**
     * Get a configuration value
     */
    public function getConfig($key, $default = null)
    {
        return $this->config[$key] ?? $default;
    }
    
    /**
     * Get application instance (singleton)
     */
    public static function getInstance()
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        
        return self::$instance;
    }
}