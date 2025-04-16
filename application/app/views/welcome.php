<!DOCTYPE html>
<html>
<head>
    <title>PHP Kickstarter Template</title>
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
        .success {
            color: green;
            font-weight: bold;
        }
        .error {
            color: red;
            font-weight: bold;
        }
        .connection-test {
            border: 1px solid #ddd;
            padding: 10px;
            margin-top: 15px;
            border-radius: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        table, th, td {
            border: 1px solid #ddd;
        }
        th, td {
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .directory-structure {
            font-family: monospace;
            white-space: pre;
            background-color: #f7f7f7;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>PHP Kickstarter Template</h1>
        <p>Welcome to your new PHP application! This is a simple template to help you get started.</p>
        
        <div class="info">
            <h2>Server Information</h2>
            <ul>
                <li>PHP Version: <?php echo phpversion(); ?></li>
                <li>Server: <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'; ?></li>
                <li>Hostname: <?php echo gethostname(); ?></li>
                <?php if (isset($visitor_count)): ?>
                <li>Total Visitors: <?php echo $visitor_count; ?></li>
                <?php endif; ?>
            </ul>
        </div>

        <?php if (isset($connection_status)): ?>
        <div class="info">
            <h2>Database Connection Test</h2>
            <div class="connection-test">
                <p>Connection Status: 
                    <span class="<?php echo $connection_status === 'Success' ? 'success' : 'error'; ?>">
                        <?php echo $connection_status; ?>
                    </span>
                </p>
                
                <?php if ($connection_status === 'Success'): ?>
                    <p>MySQL Version: <?php echo $db_version; ?></p>
                    
                    <h3>Database Tables</h3>
                    <?php if (count($tables) > 0): ?>
                        <ul>
                            <?php foreach ($tables as $table): ?>
                                <li><?php echo htmlspecialchars($table); ?></li>
                            <?php endforeach; ?>
                        </ul>
                    <?php else: ?>
                        <p>No tables found in database.</p>
                    <?php endif; ?>
                    
                    <h3>Connection Details</h3>
                    <table>
                        <tr>
                            <th>Parameter</th>
                            <th>Value</th>
                        </tr>
                        <tr>
                            <td>Host</td>
                            <td><?php echo htmlspecialchars($servername); ?></td>
                        </tr>
                        <tr>
                            <td>Database</td>
                            <td><?php echo htmlspecialchars($dbname); ?></td>
                        </tr>
                        <tr>
                            <td>Username</td>
                            <td><?php echo htmlspecialchars($username); ?></td>
                        </tr>
                        <tr>
                            <td>Connection Status</td>
                            <td class="success">Connected</td>
                        </tr>
                    </table>
                <?php else: ?>
                    <div class="error">
                        <p><strong>Connection Error:</strong> <?php echo htmlspecialchars($connection_error); ?></p>
                        
                        <h3>Connection Details</h3>
                        <table>
                            <tr>
                                <th>Parameter</th>
                                <th>Value</th>
                            </tr>
                            <tr>
                                <td>Host</td>
                                <td><?php echo htmlspecialchars($servername); ?></td>
                            </tr>
                            <tr>
                                <td>Database</td>
                                <td><?php echo htmlspecialchars($dbname); ?></td>
                            </tr>
                            <tr>
                                <td>Username</td>
                                <td><?php echo htmlspecialchars($username); ?></td>
                            </tr>
                            <tr>
                                <td>Connection Status</td>
                                <td class="error">Failed</td>
                            </tr>
                        </table>
                        
                        <p><strong>Troubleshooting Tips:</strong></p>
                        <ul>
                            <li>Check if MySQL pod/container is running</li>
                            <li>Verify database credentials in configuration</li>
                            <li>Confirm MySQL service is properly configured</li>
                            <li>Check network policies if applicable</li>
                        </ul>
                    </div>
                <?php endif; ?>
            </div>
        </div>
        <?php endif; ?>
        
        <div class="info">
            <h2>Getting Started</h2>
            <p>To start building your application:</p>
            <ol>
                <li>Create your controllers in <code>app/controllers/</code></li>
                <li>Create your models in <code>app/models/</code></li>
                <li>Create your views in <code>app/views/</code></li>
                <li>Define your routes in <code>routes/web.php</code></li>
            </ol>
            
            <h3>Directory Structure</h3>
            <div class="directory-structure">
project-root/
├── app/                    # Application core files
│   ├── config/             # Configuration files
│   ├── controllers/        # Controller files
│   ├── models/             # Database models
│   └── views/              # View templates
├── public/                 # Publicly accessible files (web root)
│   ├── assets/             # Static assets
│   └── index.php           # Entry point
├── routes/                 # Route definitions
├── src/                    # Custom PHP classes
├── storage/                # Storage for logs, cache, etc.
└── vendor/                 # Composer dependencies
            </div>
        </div>
    </div>
    
    <script src="/assets/js/app.js"></script>
</body>
</html>