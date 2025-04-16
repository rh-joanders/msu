# Controllers Directory

This directory contains the application controllers.

## What are Controllers?

Controllers handle the logic of your application. They receive input from the routes, interact with models to retrieve or modify data, and then respond with the appropriate view or JSON response.

## Creating a Controller

All controllers should extend the base `Controller` class:

```php
<?php
namespace App\Controllers;

class YourController extends Controller
{
    public function index()
    {
        // Your logic here
        
        // Render a view
        $this->view('your-view', [
            'data' => 'value'
        ]);
    }
    
    public function apiEndpoint()
    {
        // Return JSON response
        $this->json([
            'success' => true,
            'data' => 'value'
        ]);
    }
}
```

## Controller Methods

Controllers can have many methods. Each method typically corresponds to a route in your application:

```php
// In routes/web.php
Router::get('/your-route', 'YourController@index');
Router::post('/your-api', 'YourController@apiEndpoint');
```

## Best Practices

1. Keep controllers focused on a specific domain or entity
2. Controller methods should be lightweight and delegate complex logic to services or models
3. Use dependency injection rather than instantiating dependencies directly in controller methods
4. Keep your controller methods small and focused on a single responsibility
5. Use meaningful method names that describe what the method does