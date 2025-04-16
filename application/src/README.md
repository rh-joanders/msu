# Src Directory

This directory contains custom PHP classes that don't fit into the MVC pattern.

## Purpose

The `src` directory is used for:

1. Helper classes that provide utility functions
2. Service classes that encapsulate business logic
3. Libraries that provide specific functionality
4. Framework extensions or custom components

## Organization

You can organize the `src` directory based on the function of the classes:

- `Services/` - Business logic services
- `Helpers/` - Utility and helper classes
- `Libraries/` - Custom libraries or frameworks
- `Exceptions/` - Custom exception classes

## Example Classes

### Service Class

```php
<?php
namespace Src\Services;

class EmailService
{
    /**
     * Send an email
     *
     * @param string $to Recipient email
     * @param string $subject Email subject
     * @param string $message Email message
     * @param array $options Additional options
     * @return bool Success status
     */
    public function send($to, $subject, $message, $options = [])
    {
        // Email sending logic
        $headers = [
            'From' => $options['from'] ?? 'noreply@example.com',
            'Content-Type' => 'text/html; charset=UTF-8'
        ];
        
        return mail($to, $subject, $message, $headers);
    }
}
```

### Helper Class

```php
<?php
namespace Src\Helpers;

class StringHelper
{
    /**
     * Generate a random string
     *
     * @param int $length The string length
     * @param string $characters Characters to use
     * @return string The random string
     */
    public static function random($length = 10, $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
    {
        $charactersLength = strlen($characters);
        $randomString = '';
        
        for ($i = 0; $i < $length; $i++) {
            $randomString .= $characters[rand(0, $charactersLength - 1)];
        }
        
        return $randomString;
    }
    
    /**
     * Truncate a string to a specified length
     *
     * @param string $string The string to truncate
     * @param int $length The maximum length
     * @param string $append String to append if truncated
     * @return string The truncated string
     */
    public static function truncate($string, $length = 100, $append = '...')
    {
        if (strlen($string) <= $length) {
            return $string;
        }
        
        return substr($string, 0, $length) . $append;
    }
}
```

## Best Practices

1. Use namespaces to organize your classes
2. Write clear PHPDoc comments for each class and method
3. Keep classes focused on a single responsibility
4. Use static methods for utility functions that don't require state
5. Use dependency injection for services that depend on other services
6. Write unit tests for your classes
7. Follow consistent naming conventions