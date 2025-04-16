<?php
namespace App\Models;

/**
 * Visitor Model
 */
class Visitor extends Model
{
    /**
     * The database table name
     */
    protected $table = 'visitors';
    
    /**
     * Fields that can be mass assigned
     */
    protected $fillable = ['ip_address', 'user_agent'];
    
    /**
     * Get the total count of visitors
     *
     * @return int The total count
     */
    public function getTotal()
    {
        $stmt = $this->db->query("SELECT COUNT(*) as total FROM {$this->table}");
        $result = $stmt->fetch();
        return $result['total'] ?? 0;
    }
    
    /**
     * Log a new visitor
     *
     * @param string $ip The visitor's IP address
     * @param string $userAgent The visitor's user agent
     * @return int The visitor ID
     */
    public function logVisit($ip = null, $userAgent = null)
    {
        $ip = $ip ?? $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
        $userAgent = $userAgent ?? $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
        
        return $this->create([
            'ip_address' => $ip,
            'user_agent' => $userAgent,
            'visit_time' => date('Y-m-d H:i:s')
        ]);
    }
    
    /**
     * Get visitor statistics by date
     *
     * @param string $interval Day, week, or month
     * @return array Visit statistics
     */
    public function getStatsByDate($interval = 'day')
    {
        $groupFormat = '%Y-%m-%d';
        
        switch ($interval) {
            case 'week':
                $groupFormat = '%Y-%u'; // ISO week number
                break;
            case 'month':
                $groupFormat = '%Y-%m';
                break;
        }
        
        $sql = "SELECT 
                    DATE_FORMAT(visit_time, :format) as period,
                    COUNT(*) as visits
                FROM {$this->table}
                GROUP BY period
                ORDER BY visit_time";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute(['format' => $groupFormat]);
        return $stmt->fetchAll();
    }
}