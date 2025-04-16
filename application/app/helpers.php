<?php
/**
 * Helper Functions
 * 
 * This file contains global helper functions that can be used throughout the application.
 */

/**
 * Get the base URL of the application
 *
 * @return string The base URL
 */
function baseUrl()
{
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost:8080';
    return "{$protocol}://{$host}";
}

/**
 * Generate a URL from a path
 *
 * @param string $path The path
 * @return string The full URL
 */
function url($path)
{
    $path = ltrim($path, '/');
    return baseUrl() . '/' . $path;
}

/**
 * HTML escape a string
 *
 * @param string $string The string to escape
 * @return string The escaped string
 */
function e($string)
{
    return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
}

/**
 * Get a configuration value
 *
 * @param string $key The configuration key
 * @param mixed $default The default value if the key doesn't exist
 * @return mixed The configuration value
 */
function config($key, $default = null)
{
    $app = \App\Core\Application::getInstance();
    return $app->getConfig($key, $default);
}

/**
 * Format a date
 *
 * @param string $date The date string
 * @param string $format The format (default: Y-m-d H:i:s)
 * @return string The formatted date
 */
function formatDate($date, $format = 'Y-m-d H:i:s')
{
    return date($format, strtotime($date));
}

/**
 * Redirect to a URL
 *
 * @param string $url The URL to redirect to
 * @return void
 */
function redirect($url)
{
    header("Location: {$url}");
    exit;
}

/**
 * Get a value from the session
 *
 * @param string $key The session key
 * @param mixed $default The default value if the key doesn't exist
 * @return mixed The session value
 */
function session($key, $default = null)
{
    if (!isset($_SESSION)) {
        session_start();
    }
    
    return $_SESSION[$key] ?? $default;
}

/**
 * Set a value in the session
 *
 * @param string $key The session key
 * @param mixed $value The value to set
 * @return void
 */
function sessionSet($key, $value)
{
    if (!isset($_SESSION)) {
        session_start();
    }
    
    $_SESSION[$key] = $value;
}

/**
 * Flash a message to the session
 *
 * @param string $key The flash key
 * @param mixed $value The value to flash
 * @return void
 */
function flash($key, $value)
{
    sessionSet('_flash_' . $key, $value);
}

/**
 * Get a flashed message from the session
 *
 * @param string $key The flash key
 * @param mixed $default The default value if the key doesn't exist
 * @return mixed The flashed value
 */
function flashGet($key, $default = null)
{
    $value = session('_flash_' . $key, $default);
    
    // Remove the flashed message
    if (isset($_SESSION['_flash_' . $key])) {
        unset($_SESSION['_flash_' . $key]);
    }
    
    return $value;
}

/**
 * Check if a flash message exists
 *
 * @param string $key The flash key
 * @return bool True if the flash message exists
 */
function hasFlash($key)
{
    return isset($_SESSION['_flash_' . $key]);
}

/**
 * Generate a CSRF token
 *
 * @return string The CSRF token
 */
function csrfToken()
{
    if (!isset($_SESSION)) {
        session_start();
    }
    
    if (!isset($_SESSION['_csrf_token'])) {
        $_SESSION['_csrf_token'] = bin2hex(random_bytes(32));
    }
    
    return $_SESSION['_csrf_token'];
}

/**
 * Output a CSRF token field
 *
 * @return string The CSRF token field HTML
 */
function csrfField()
{
    return '<input type="hidden" name="_csrf_token" value="' . csrfToken() . '">';
}

/**
 * Verify CSRF token
 *
 * @param string $token The token to verify
 * @return bool True if the token is valid
 */
function verifyCsrf($token)
{
    if (!isset($_SESSION)) {
        session_start();
    }
    
    return isset($_SESSION['_csrf_token']) && hash_equals($_SESSION['_csrf_token'], $token);
}

/**
 * Log a message
 *
 * @param string $message The message to log
 * @param string $level The log level (info, warning, error)
 * @return void
 */
function logMessage($message, $level = 'info')
{
    $logFile = APP_ROOT . '/storage/logs/' . date('Y-m-d') . '.log';
    $timestamp = date('Y-m-d H:i:s');
    $messageFormatted = "[{$timestamp}] [{$level}] {$message}" . PHP_EOL;
    
    // Make sure the directory exists
    $logDir = dirname($logFile);
    if (!is_dir($logDir)) {
        mkdir($logDir, 0777, true);
    }
    
    // Append to the log file
    file_put_contents($logFile, $messageFormatted, FILE_APPEND);
}

/**
 * Generate a random string
 *
 * @param int $length The length of the string
 * @return string The random string
 */
function randomString($length = 10)
{
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $charactersLength = strlen($characters);
    $randomString = '';
    
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, $charactersLength - 1)];
    }
    
    return $randomString;
}