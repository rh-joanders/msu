# Troubleshooting Guide

This guide helps you resolve common issues with the PHP Kickstarter Template.

## Common Issues

### Class not found errors

If you're seeing errors like `Class "App\Core\Application" not found`, it's likely due to one of these issues:

1. **Case sensitivity mismatch**: PHP is case-sensitive on many systems (especially Linux, which Docker uses). Make sure file names match class names exactly.

2. **Missing directories**: Some required directories might not be created correctly.

3. **Autoloading not working**: If you've installed via Composer, make sure autoloading is set up correctly.

## Quick Fixes

### Option 1: Run the fix script

Run the included fix script to correct directory structure and file naming issues:

```bash
php fix_structure.php
```

### Option 2: Manual fixes

If the automatic fix doesn't resolve your issues, try these manual steps:

1. **Correct case sensitivity issues**:
   - Ensure app/Core/Application.php exists (not app/core/application.php)
   - Ensure app/Controllers/Controller.php exists
   - Ensure app/Models/Model.php exists
   - Ensure routes/web.php exists

2. **Fix namespaces**:
   - Check that class names match namespaces in each file
   - Controller classes should be in App\Controllers namespace
   - Model classes should be in App\Models namespace
   - Core classes should be in App\Core namespace

3. **Check file structure**:
   - The public directory should be your web root
   - public/index.php is the entry point

## Running the Application

### With Docker

```bash
# Build and run with Docker Compose
docker-compose up -d

# Access the application at http://localhost:8080
```

### With PHP's built-in server

```bash
# Navigate to the project directory
cd your-project-dir

# Start the built-in server
php -S localhost:8080 -t public

# Access the application at http://localhost:8080
```

## Checking Logs

If you're still having issues, check the logs:

```bash
# Check PHP error logs
tail -f storage/logs/*.log

# Check container logs (if using Docker)
docker-compose logs -f
```

## Need More Help?

If you're still having issues, please open an issue on the GitHub repository with:
1. The exact error message
2. Your PHP version
3. Your operating system
4. Steps to reproduce the issue