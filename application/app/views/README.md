# Views Directory

This directory contains the application views.

## What are Views?

Views are responsible for displaying data to the user. They are essentially HTML templates with embedded PHP code that render the UI of your application.

## Creating a View

Views are PHP files that contain HTML and PHP code. They are typically organized into subdirectories based on the controller that uses them.

Example view file (`app/views/users/profile.php`):

```php
<!DOCTYPE html>
<html>
<head>
    <title>User Profile - <?= htmlspecialchars($user['name']) ?></title>
    <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body>
    <div class="container">
        <h1>User Profile</h1>
        
        <div class="card">
            <div class="card-header">
                <h2><?= htmlspecialchars($user['name']) ?></h2>
            </div>
            <div class="card-body">
                <p><strong>Email:</strong> <?= htmlspecialchars($user['email']) ?></p>
                <p><strong>Member Since:</strong> <?= formatDate($user['created_at'], 'F j, Y') ?></p>
                
                <?php if (!empty($user['bio'])): ?>
                    <h3>Bio</h3>
                    <p><?= htmlspecialchars($user['bio']) ?></p>
                <?php endif; ?>
            </div>
        </div>
    </div>
    
    <script src="/assets/js/app.js"></script>
</body>
</html>
```

## Using Views in Controllers

You can render views from your controllers using the `view()` method:

```php
// In a controller method
public function profile($id)
{
    // Get user from model
    $userModel = new User();
    $user = $userModel->find($id);
    
    // Render the view with data
    $this->view('users/profile', [
        'user' => $user
    ]);
}
```

## Partials

Partials are reusable view components that can be included in multiple views. They are typically stored in a `partials` subdirectory.

Example partial (`app/views/partials/header.php`):

```php
<!DOCTYPE html>
<html>
<head>
    <title><?= $title ?? 'PHP Kickstarter' ?></title>
    <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body>
    <header>
        <nav>
            <a href="/">Home</a>
            <a href="/about">About</a>
            <a href="/contact">Contact</a>
        </nav>
    </header>
    
    <div class="container">
```

You can include partials in your views using the `include` statement:

```php
<?php include APP_ROOT . '/app/views/partials/header.php'; ?>

<h1>Main Content</h1>
<p>This is the main content of the page.</p>

<?php include APP_ROOT . '/app/views/partials/footer.php'; ?>
```

## Best Practices

1. Keep your views focused on presentation logic only
2. Always escape output with `htmlspecialchars()` or the `e()` helper function
3. Organize views into subdirectories based on controllers or features
4. Use partials for reusable components like headers, footers, and navigation
5. Keep complex logic in controllers or models, not in views
6. Use consistent naming conventions (e.g., `controller/action.php`)
7. Consider using a templating engine for more complex views