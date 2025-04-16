<?php
namespace App\Controllers;

use App\Models\Visitor;

/**
 * Home Controller
 */
class HomeController extends Controller
{
    /**
     * Display the home page
     */
    public function index()
    {
        // Log the visit
        $visitor = new Visitor();
        $visitor->logVisit();
        
        // Get visitor count
        $visitor_count = $visitor->getTotal();
        
        // Get database connection info
        $servername = getenv('MYSQL_SERVICE_HOST') ?: "mysql";
        $username = getenv('MYSQL_USER') ?: "lamp_user";
        $password = getenv('MYSQL_PASSWORD') ?: "lamp_password";
        $dbname = getenv('MYSQL_DATABASE') ?: "lamp_db";
        
        // Get database version and connection status
        $connection_status = "Not attempted";
        $connection_error = "";
        $db_version = "";
        $tables = [];
        
        try {
            // Create connection
            $conn = new \mysqli($servername, $username, $password, $dbname);

            // Check connection
            if ($conn->connect_error) {
                $connection_status = "Failed";
                $connection_error = $conn->connect_error;
                throw new \Exception("Connection failed: " . $conn->connect_error);
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
                while ($table_row = $table_result->fetch_array(\MYSQLI_NUM)) {
                    $tables[] = $table_row[0];
                }
            }
            
            // Close the database connection
            $conn->close();
            
        } catch (\Exception $e) {
            // Handle exception
            if ($connection_status !== "Failed") {
                $connection_status = "Error";
                $connection_error = $e->getMessage();
            }
        }
        
        // Render the view with data
        $this->view('welcome', [
            'visitor_count' => $visitor_count,
            'servername' => $servername,
            'username' => $username,
            'password' => $password,
            'dbname' => $dbname,
            'connection_status' => $connection_status,
            'connection_error' => $connection_error,
            'db_version' => $db_version,
            'tables' => $tables
        ]);
    }
    
    /**
     * Display the about page
     */
    public function about()
    {
        $this->view('about', [
            'title' => 'About Us',
            'content' => 'This is a simple PHP kickstarter template application.'
        ]);
    }
    
    /**
     * API endpoint for visitor statistics
     */
    public function stats()
    {
        $visitor = new Visitor();
        
        // Get interval from query string
        $interval = $this->input('interval', 'day');
        
        // Get stats by date
        $stats = $visitor->getStatsByDate($interval);
        
        // Return as JSON
        $this->json([
            'success' => true,
            'total' => $visitor->getTotal(),
            'interval' => $interval,
            'stats' => $stats
        ]);
    }
}