<?php
namespace Src;

/**
 * Router Class
 * 
 * Handles routing for the application
 */
class Router
{
    /**
     * Array of registered routes
     */
    private static $routes = [];
    
    /**
     * Parameters from route patterns
     */
    private static $params = [];
    
    /**
     * Register a GET route
     *
     * @param string $route The route URL pattern
     * @param mixed $handler The route handler (function or controller@method)
     * @return void
     */
    public static function get($route, $handler)
    {
        self::addRoute('GET', $route, $handler);
    }
    
    /**
     * Register a POST route
     *
     * @param string $route The route URL pattern
     * @param mixed $handler The route handler (function or controller@method)
     * @return void
     */
    public static function post($route, $handler)
    {
        self::addRoute('POST', $route, $handler);
    }
    
    /**
     * Register a PUT route
     *
     * @param string $route The route URL pattern
     * @param mixed $handler The route handler (function or controller@method)
     * @return void
     */
    public static function put($route, $handler)
    {
        self::addRoute('PUT', $route, $handler);
    }
    
    /**
     * Register a DELETE route
     *
     * @param string $route The route URL pattern
     * @param mixed $handler The route handler (function or controller@method)
     * @return void
     */
    public static function delete($route, $handler)
    {
        self::addRoute('DELETE', $route, $handler);
    }
    
    /**
     * Register a route with any HTTP method
     *
     * @param string $method The HTTP method (GET, POST, etc.)
     * @param string $route The route URL pattern
     * @param mixed $handler The route handler (function or controller@method)
     * @return void
     */
    private static function addRoute($method, $route, $handler)
    {
        // Convert route to regex for parameter matching
        $route = preg_replace('/\{([a-z]+)\}/', '(?P<\1>[^/]+)', $route);
        $route = "#^{$route}$#i";
        
        self::$routes[$method][$route] = $handler;
    }
    
    /**
     * Match the request to a route and execute the handler
     *
     * @param string $method The HTTP method of the request
     * @param string $uri The request URI
     * @return mixed The response from the route handler
     */
    public static function match($method, $uri)
    {
        // Check if routes exist for this method
        if (!isset(self::$routes[$method])) {
            return false;
        }
        
        // Match the URI to a route pattern
        foreach (self::$routes[$method] as $route => $handler) {
            if (preg_match($route, $uri, $matches)) {
                // Extract named parameters
                foreach ($matches as $key => $match) {
                    if (is_string($key)) {
                        self::$params[$key] = $match;
                    }
                }
                
                // Mark that we found a route
                define('ROUTE_MATCHED', true);
                
                // Execute the handler
                return self::executeHandler($handler);
            }
        }
        
        return false;
    }
    
    /**
     * Execute a route handler
     *
     * @param mixed $handler The route handler
     * @return mixed The response from the handler
     */
    private static function executeHandler($handler)
    {
        // If handler is a closure or function
        if (is_callable($handler)) {
            return call_user_func_array($handler, self::$params);
        }
        
        // If handler is a controller@method string
        if (is_string($handler) && strpos($handler, '@') !== false) {
            list($controller, $method) = explode('@', $handler);
            
            // Try both namespaces
            $controllerClass = "\\App\\Controllers\\{$controller}";
            if (!class_exists($controllerClass)) {
                $controllerClass = "\\App\\{$controller}";
            }
            
            if (class_exists($controllerClass)) {
                $controllerInstance = new $controllerClass();
                if (method_exists($controllerInstance, $method)) {
                    return call_user_func_array([$controllerInstance, $method], self::$params);
                }
            }
        }
        
        throw new \Exception("Route handler not found: {$handler}");
    }
    
    /**
     * Get a route parameter
     *
     * @param string $name The parameter name
     * @param mixed $default The default value if parameter doesn't exist
     * @return mixed The parameter value
     */
    public static function getParam($name, $default = null)
    {
        return self::$params[$name] ?? $default;
    }
    
    /**
     * Get all route parameters
     *
     * @return array The parameters
     */
    public static function getParams()
    {
        return self::$params;
    }
}