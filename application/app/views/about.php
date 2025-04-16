<!DOCTYPE html>
<html>
<head>
    <title><?php echo htmlspecialchars($title); ?> - PHP Kickstarter</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/assets/css/style.css">
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            line-height: 1.6;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #4a69bd;
        }
        .info {
            background-color: #ffffff;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
        }
        nav {
            margin-bottom: 20px;
        }
        nav a {
            display: inline-block;
            padding: 8px 16px;
            background-color: #4a69bd;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            margin-right: 10px;
        }
        nav a:hover {
            background-color: #3d5af1;
        }
    </style>
</head>
<body>
    <div class="container">
        <nav>
            <a href="/">Home</a>
            <a href="/about">About</a>
        </nav>
        
        <h1><?php echo htmlspecialchars($title); ?></h1>
        
        <div class="info">
            <p><?php echo htmlspecialchars($content); ?></p>
            
            <h2>PHP Kickstarter Template</h2>
            <p>This is a simple yet powerful PHP template to kickstart your web application development. It provides:</p>
            
            <ul>
                <li>Clean directory structure following modern PHP best practices</li>
                <li>Simple MVC architecture</li>
                <li>Database abstraction with both MySQLi and PDO support</li>
                <li>Easy routing system</li>
                <li>Containerization with Docker</li>
                <li>Ready for deployment to OpenShift</li>
            </ul>
            
            <h2>Getting Started</h2>
            <p>To start building your application:</p>
            <ol>
                <li>Create your controllers in <code>app/controllers/</code></li>
                <li>Create your models in <code>app/models/</code></li>
                <li>Create your views in <code>app/views/</code></li>
                <li>Define your routes in <code>routes/web.php</code></li>
            </ol>
            
            <p>For more information, check out the <a href="https://github.com/your-username/php-kickstarter">documentation</a>.</p>
        </div>
    </div>
    
    <script src="/assets/js/app.js"></script>
</body>
</html>