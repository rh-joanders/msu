<?php
// Database connection parameters - from environment variables with fallbacks
$servername = getenv('MYSQL_SERVICE_HOST') ?: "mysql";
$username = getenv('MYSQL_USER') ?: "lamp_user";
$password = getenv('MYSQL_PASSWORD') ?: "lamp_password";
$dbname = getenv('MYSQL_DATABASE') ?: "lamp_db";

// Create connection to MySQL
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Check if table exists, if not create it
// This ensures our application works the first time it's launched
$sql = "CREATE TABLE IF NOT EXISTS visitors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)";

if ($conn->query($sql) !== TRUE) {
    echo "Error creating table: " . $conn->error;
}

// Insert a new record for this visit
$sql = "INSERT INTO visitors (visit_time) VALUES (NOW())";
$conn->query($sql);

// Get visitor count
$sql = "SELECT COUNT(*) as total FROM visitors";
$result = $conn->query($sql);
$row = $result->fetch_assoc();
$total = $row["total"];

// Close the database connection
$conn->close();
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
                <li>MySQL Connection: Successful</li>
                <li>Total Visitors: <?php echo $total; ?></li>
            </ul>
        </div>
        
        <div class="info">
            <h2>Environment Variables</h2>
            <pre><?php print_r($_ENV); ?></pre>
        </div>
    </div>
</body>
</html>