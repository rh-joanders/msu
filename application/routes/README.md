# Routes Directory

This directory contains the application routes.

## What are Routes?

Routes define the URLs that your application responds to and how it handles those requests. They map URLs to controller actions or closure functions.

## Route Files

- `web.php` - Routes for web pages (HTML responses)
- `api.php` - Routes for API endpoints (JSON responses)
- `admin.php` - Routes for admin pages (if needed)
- `auth.php` - Routes for authentication (if needed)

## Defining Routes

Routes are defined using the `Router` class:

```php
// Simple route with closure
Router::get('/', function() {
    echo "Hello, World!";
});

// Route to controller method
Router::get('/users', 'UserController@index');
Router::post('/users', 'UserController@store');
Router::get('/users/{id}', 'UserController@show');
Router::put('/users/{id}', 'UserController@update');
Router::delete('/users/{id}', 'UserController@destroy');

// Route with middleware
Router::get('/admin', 'AdminController@dashboard', ['auth', 'admin']);

// Route groups
Router::group(['prefix' => 'api', 'middleware' => ['api']], function() {
    Router::get('/users', 'Api\UserController@index');
    Router::post('/users', 'Api\UserController@store');
});
```

## Route Parameters

You can define route parameters using curly braces `{}`:

```php
Router::get('/users/{id}', function($id) {
    echo "User ID: " . $id;
});

Router::get('/posts/{slug}', 'PostController@show');
```

## HTTP Methods

The Router supports all standard HTTP methods:

```php
Router::get('/users', 'UserController@index');
Router::post('/users', 'UserController@store');
Router::put('/users/{id}', 'UserController@update');
Router::patch('/users/{id}', 'UserController@update');
Router::delete('/users/{id}', 'UserController@destroy');
Router::options('/users', 'UserController@options');
```

You can also register a route for multiple HTTP methods:

```php
Router::match(['get', 'post'], '/users', 'UserController@handleRequest');
```

Or for any HTTP method:

```php
Router::any('/webhook', 'WebhookController@handle');
```

## Best Practices

1. Organize routes logically by function (web, API, admin, etc.)
2. Use RESTful naming conventions for resource routes
3. Keep route definitions simple and delegate logic to controllers
4. Use route parameters for dynamic segments
5. Group related routes together
6. Use middleware for cross-cutting concerns like authentication