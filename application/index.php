<?php
// Database connection parameters - from environment variables with fallbacks
$servername = getenv('MYSQL_SERVICE_HOST') ?: "mysql";
$username = getenv('MYSQL_USER') ?: "lamp_user";
$password = getenv('MYSQL_PASSWORD') ?: "lamp_password";
$dbname = getenv('MYSQL_DATABASE') ?: "lamp_db";

// Connection status variables
$connection_status = "Not attempted";
$connection_error = "";
$db_version = "";
$tables = [];
$visitor_count = 0;

// Try to connect to MySQL with detailed error reporting
try {
    // Create connection
    $conn = new mysqli($servername, $username, $password, $dbname);

    // Check connection
    if ($conn->connect_error) {
        $connection_status = "Failed";
        $connection_error = $conn->connect_error;
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    // Connection successful - get MySQL version
    $result = $conn->query("SELECT VERSION() as version");
    if ($result && $row = $result->fetch_assoc()) {
        $db_version = $row['version'];
    }
    
    $connection_status = "Success";
    
    // Get list of tables to verify database structure
    $table_result = $conn->query("SHOW TABLES");
    if ($table_result) {
        while ($table_row = $table_result->fetch_array(MYSQLI_NUM)) {
            $tables[] = $table_row[0];
        }
    }

    // Check if table exists, if not create it
    // This ensures our application works the first time it's launched
    $sql = "CREATE TABLE IF NOT EXISTS visitors (
        id INT AUTO_INCREMENT PRIMARY KEY,
        visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ip_address VARCHAR(45),
        user_agent VARCHAR(255)
    )";

    if ($conn->query($sql) !== TRUE) {
        throw new Exception("Error creating table: " . $conn->error);
    }

    // Insert a new record for this visit with additional information
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
    $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
    
    $stmt = $conn->prepare("INSERT INTO visitors (visit_time, ip_address, user_agent) VALUES (NOW(), ?, ?)");
    $stmt->bind_param("ss", $ip, $user_agent);
    $stmt->execute();
    $stmt->close();

    // Get visitor count
    $sql = "SELECT COUNT(*) as total FROM visitors";
    $result = $conn->query($sql);
    if ($result && $row = $result->fetch_assoc()) {
        $visitor_count = $row["total"];
    }

    // Close the database connection
    $conn->close();
    
} catch (Exception $e) {
    // Handle exception
    if ($connection_status !== "Failed") {
        $connection_status = "Error";
        $connection_error = $e->getMessage();
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>OpenShift LAMP Stack Demo</title>
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
            color: #cc0000;
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
    </style>
</head>
<body>
    <div class="container">
        <h1>OpenShift LAMP Stack Demo</h1>
        <p>This is a simple PHP application running on Apache with MySQL database.</p>
        
        <div class="info">
            <h2>Server Information</h2>
            <ul>
                <li>PHP Version: <?php echo phpversion(); ?></li>
                <li>Server: <?php echo $_SERVER['SERVER_SOFTWARE']; ?></li>
                <li>Hostname: <?php echo gethostname(); ?></li>
                <li>Total Visitors: <?php echo $visitor_count; ?></li>
            </ul>
        </div>
        
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
                            <li>Check if MySQL pod is running</li>
                            <li>Verify database credentials in secret</li>
                            <li>Confirm MySQL service is properly configured</li>
                            <li>Check network policies if applicable</li>
                        </ul>
                    </div>
                <?php endif; ?>
            </div>
        </div>
        
        <div class="info">
            <h2>Environment Variables</h2>
            <pre><?php print_r($_ENV); ?></pre>
        </div>
    </div>
</body>
</html>