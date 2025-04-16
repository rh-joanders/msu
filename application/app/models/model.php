<?php
namespace App\Models;

/**
 * Base Model
 * 
 * All models should extend this class
 */
abstract class Model
{
    /**
     * The database table name
     */
    protected $table;
    
    /**
     * The primary key field
     */
    protected $primaryKey = 'id';
    
    /**
     * Fields that can be mass assigned
     */
    protected $fillable = [];
    
    /**
     * Fields that are not mass assignable
     */
    protected $guarded = [];
    
    /**
     * Database connection
     */
    protected $db;
    
    /**
     * Constructor
     */
    public function __construct()
    {
        // Get database connection
        $this->db = getPdoConnection();
        
        // If table name is not set, derive it from class name
        if (!$this->table) {
            $className = get_class($this);
            $parts = explode('\\', $className);
            $modelName = end($parts);
            $this->table = strtolower($modelName) . 's';
        }
    }
    
    /**
     * Find a record by primary key
     *
     * @param mixed $id The primary key value
     * @return mixed The found record or null
     */
    public function find($id)
    {
        $stmt = $this->db->prepare("SELECT * FROM {$this->table} WHERE {$this->primaryKey} = :id LIMIT 1");
        $stmt->execute(['id' => $id]);
        return $stmt->fetch();
    }
    
    /**
     * Get all records
     *
     * @return array All records
     */
    public function all()
    {
        $stmt = $this->db->query("SELECT * FROM {$this->table}");
        return $stmt->fetchAll();
    }
    
    /**
     * Create a new record
     *
     * @param array $data The data to insert
     * @return int The last insert ID
     */
    public function create($data)
    {
        // Filter data for fillable or guarded fields
        $data = $this->filterData($data);
        
        // Build query
        $fields = array_keys($data);
        $placeholders = array_map(function($field) {
            return ":{$field}";
        }, $fields);
        
        $fieldsStr = implode(', ', $fields);
        $placeholdersStr = implode(', ', $placeholders);
        
        $sql = "INSERT INTO {$this->table} ({$fieldsStr}) VALUES ({$placeholdersStr})";
        
        // Execute query
        $stmt = $this->db->prepare($sql);
        $stmt->execute($data);
        
        return $this->db->lastInsertId();
    }
    
    /**
     * Update a record
     *
     * @param mixed $id The primary key value
     * @param array $data The data to update
     * @return bool True if successful
     */
    public function update($id, $data)
    {
        // Filter data for fillable or guarded fields
        $data = $this->filterData($data);
        
        // Build set clause
        $setClause = [];
        foreach ($data as $field => $value) {
            $setClause[] = "{$field} = :{$field}";
        }
        $setClauseStr = implode(', ', $setClause);
        
        // Add ID to data for WHERE clause
        $data[$this->primaryKey] = $id;
        
        $sql = "UPDATE {$this->table} SET {$setClauseStr} WHERE {$this->primaryKey} = :{$this->primaryKey}";
        
        // Execute query
        $stmt = $this->db->prepare($sql);
        return $stmt->execute($data);
    }
    
    /**
     * Delete a record
     *
     * @param mixed $id The primary key value
     * @return bool True if successful
     */
    public function delete($id)
    {
        $sql = "DELETE FROM {$this->table} WHERE {$this->primaryKey} = :id";
        $stmt = $this->db->prepare($sql);
        return $stmt->execute(['id' => $id]);
    }
    
    /**
     * Filter data based on fillable or guarded fields
     *
     * @param array $data The data to filter
     * @return array Filtered data
     */
    protected function filterData($data)
    {
        $filtered = [];
        
        if (!empty($this->fillable)) {
            // Only allow fillable fields
            foreach ($this->fillable as $field) {
                if (isset($data[$field])) {
                    $filtered[$field] = $data[$field];
                }
            }
        } else if (!empty($this->guarded)) {
            // Allow everything except guarded fields
            foreach ($data as $field => $value) {
                if (!in_array($field, $this->guarded)) {
                    $filtered[$field] = $value;
                }
            }
        } else {
            // No filtering
            $filtered = $data;
        }
        
        return $filtered;
    }
    
    /**
     * Execute a custom query
     *
     * @param string $sql The SQL query
     * @param array $params The query parameters
     * @return array The query results
     */
    public function raw($sql, $params = [])
    {
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }
    
    /**
     * Find records with where clause
     *
     * @param string $field The field to check
     * @param string $operator The comparison operator
     * @param mixed $value The value to compare against
     * @return array The matching records
     */
    public function where($field, $operator, $value = null)
    {
        // If only 2 arguments are provided, assume = operator
        if ($value === null) {
            $value = $operator;
            $operator = '=';
        }
        
        $sql = "SELECT * FROM {$this->table} WHERE {$field} {$operator} :value";
        $stmt = $this->db->prepare($sql);
        $stmt->execute(['value' => $value]);
        return $stmt->fetchAll();
    }
}