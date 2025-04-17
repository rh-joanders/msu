<?php
/**
 * Web Routes
 * 
 * Define your application routes here.
 * Format: Router::get('/path', 'ControllerName@methodName');
 */

// Make sure the Router class exists
if (!class_exists('Src\Router')) {
    // Create a simple router class if it doesn't exist
    class Router {
        private static $routes = [];
        
        /**
         * Register a GET route
         */
        public static function get($path, $handler) {
            self::$routes['GET'][$path] = $handler;
        }
        
        /**
         * Register a POST route
         */
        public static function post($path, $handler) {
            self::$routes['POST'][$path] = $handler;
        }
        
        /**
         * Match the current request to a route
         */
        public static function match($method, $uri) {
            if (isset(self::$routes[$method][$uri])) {
                define('ROUTE_MATCHED', true);
                $handler = self::$routes[$method][$uri];
                
                if (is_callable($handler)) {
                    return call_user_func($handler);
                }
                
                // Handle controller@method format
                if (is_string($handler) && strpos($handler, '@') !== false) {
                    list($controller, $method) = explode('@', $handler);
                    $controllerClass = "\\App\\Controllers\\{$controller}";
                    
                    if (class_exists($controllerClass)) {
                        $controllerInstance = new $controllerClass();
                        if (method_exists($controllerInstance, $method)) {
                            return call_user_func([$controllerInstance, $method]);
                        }
                    }
                }
            }
            
            return false;
        }
    }
}

// Define your routes here
// Router::get('/', 'HomeController@index');
// Router::get('/about', 'HomeController@about');
// Router::get('/api/stats', 'HomeController@stats');

// Process the current request
$requestMethod = $_SERVER['REQUEST_METHOD'];
$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Try to match a route
if (class_exists('Router')) {
    Router::match($requestMethod, $requestUri);
}