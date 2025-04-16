<?php
namespace App\Controllers;

/**
 * Base Controller
 * 
 * All controllers should extend this class
 */
class Controller
{
    /**
     * Render a view
     *
     * @param string $view Path to the view file
     * @param array $data Data to pass to the view
     * @return void
     */
    protected function view($view, $data = [])
    {
        // Extract data to make variables available to the view
        extract($data);
        
        // Build the view path
        $viewPath = APP_ROOT . '/app/views/' . $view . '.php';
        
        // Check if view exists
        if (!file_exists($viewPath)) {
            throw new \Exception("View {$view} not found");
        }
        
        // Include the view
        include $viewPath;
    }
    
    /**
     * Redirect to a URL
     *
     * @param string $url The URL to redirect to
     * @return void
     */
    protected function redirect($url)
    {
        header("Location: {$url}");
        exit;
    }
    
    /**
     * Return JSON response
     *
     * @param mixed $data The data to encode as JSON
     * @param int $status HTTP status code
     * @return void
     */
    protected function json($data, $status = 200)
    {
        header('Content-Type: application/json');
        http_response_code($status);
        echo json_encode($data);
        exit;
    }
    
    /**
     * Get input from request
     *
     * @param string $key The input key
     * @param mixed $default Default value if key doesn't exist
     * @return mixed The input value
     */
    protected function input($key, $default = null)
    {
        return $_REQUEST[$key] ?? $default;
    }
    
    /**
     * Get all inputs from request
     *
     * @return array All inputs
     */
    protected function all()
    {
        return $_REQUEST;
    }
    
    /**
     * Check if input exists
     *
     * @param string $key The input key
     * @return bool True if input exists
     */
    protected function has($key)
    {
        return isset($_REQUEST[$key]);
    }
    
    /**
     * Validate input data
     *
     * @param array $rules Validation rules
     * @return array Validation errors
     */
    protected function validate($rules)
    {
        $errors = [];
        
        foreach ($rules as $field => $rule) {
            // Split rules by |
            $ruleList = explode('|', $rule);
            
            foreach ($ruleList as $singleRule) {
                // Check if rule has parameters
                if (strpos($singleRule, ':') !== false) {
                    list($ruleName, $ruleParams) = explode(':', $singleRule, 2);
                    $ruleParams = explode(',', $ruleParams);
                } else {
                    $ruleName = $singleRule;
                    $ruleParams = [];
                }
                
                // Get value from input
                $value = $this->input($field);
                
                // Apply rule
                switch ($ruleName) {
                    case 'required':
                        if (empty($value)) {
                            $errors[$field][] = "{$field} is required";
                        }
                        break;
                    case 'min':
                        $min = $ruleParams[0] ?? 0;
                        if (strlen($value) < $min) {
                            $errors[$field][] = "{$field} must be at least {$min} characters";
                        }
                        break;
                    case 'max':
                        $max = $ruleParams[0] ?? 255;
                        if (strlen($value) > $max) {
                            $errors[$field][] = "{$field} must be at most {$max} characters";
                        }
                        break;
                    case 'email':
                        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
                            $errors[$field][] = "{$field} must be a valid email";
                        }
                        break;
                }
            }
        }
        
        return $errors;
    }
}