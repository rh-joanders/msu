# Tests Directory

This directory contains test files for your application.

## Structure

- `/Unit` - Unit tests
- `/Feature` - Feature/integration tests
- `/Browser` - Browser/UI tests (if needed)
- `bootstrap.php` - Test bootstrap file
- `TestCase.php` - Base test case class

## Unit Tests

Unit tests focus on testing individual components (classes, methods, functions) in isolation. They should be small, fast, and not depend on external resources like databases or APIs.

Example unit test:

```php
<?php
namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use App\Models\User;

class UserTest extends TestCase
{
    public function testUserCanBeCreated()
    {
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123'
        ];
        
        $user = new User();
        $user->fill($userData);
        
        $this->assertEquals('John Doe', $user->name);
        $this->assertEquals('john@example.com', $user->email);
    }
    
    public function testEmailValidation()
    {
        $user = new User();
        
        $this->assertFalse($user->validateEmail('invalid-email'));
        $this->assertTrue($user->validateEmail('valid@example.com'));
    }
}
```

## Feature Tests

Feature tests focus on testing multiple components working together. They might interact with a database, file system, or other external resources.

Example feature test:

```php
<?php
namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;

class AuthenticationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        
        // Setup test database
        $this->setupTestDatabase();
    }
    
    public function testUserCanLogin()
    {
        // Create a user
        $user = new User();
        $user->create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => password_hash('password123', PASSWORD_DEFAULT)
        ]);
        
        // Simulate a login request
        $response = $this->post('/login', [
            'email' => 'john@example.com',
            'password' => 'password123'
        ]);
        
        // Assert the user is logged in
        $this->assertEquals('John Doe', $_SESSION['user']['name']);
        $this->assertTrue($_SESSION['logged_in']);
    }
}
```

## Running Tests

You can run tests using PHPUnit:

```bash
# Run all tests
./vendor/bin/phpunit

# Run a specific test file
./vendor/bin/phpunit tests/Unit/UserTest.php

# Run tests with a specific filter
./vendor/bin/phpunit --filter=testUserCanLogin
```

## Best Practices

1. Write tests before or along with your code (Test-Driven Development)
2. Aim for high test coverage, especially for critical components
3. Keep tests fast and independent from each other
4. Use mock objects to isolate tests from external dependencies
5. Test both happy paths and edge cases/error conditions
6. Organize tests to mirror your application structure
7. Use descriptive test method names (testUserCanLogin, testEmailValidation, etc.)
8. Set up and tear down test data properly to avoid test pollution