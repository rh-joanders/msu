# Models Directory

This directory contains the application models.

## What are Models?

Models represent the data structure of your application and provide methods to interact with the database. They encapsulate the business logic and data access rules.

## Creating a Model

All models should extend the base `Model` class:

```php
<?php
namespace App\Models;

class YourModel extends Model
{
    // The table associated with the model
    protected $table = 'your_table';
    
    // The primary key for the model
    protected $primaryKey = 'id';
    
    // The attributes that are mass assignable
    protected $fillable = [
        'field1', 'field2', 'field3'
    ];
    
    // The attributes that aren't mass assignable
    protected $guarded = [
        'id', 'created_at', 'updated_at'
    ];
    
    // Custom methods for your model
    public function customMethod()
    {
        // Your logic here
    }
}
```

## Using Models

Once you've created a model, you can use it in your controllers or other parts of your application:

```php
// Create a new instance
$model = new YourModel();

// Find a record by ID
$record = $model->find(1);

// Get all records
$allRecords = $model->all();

// Create a new record
$id = $model->create([
    'field1' => 'value1',
    'field2' => 'value2'
]);

// Update a record
$model->update(1, [
    'field1' => 'new value'
]);

// Delete a record
$model->delete(1);

// Custom query
$results = $model->where('field1', 'value1');
```

## Relationships

You can define relationships between models by adding methods to your model class:

```php
// One-to-many relationship
public function posts()
{
    // This assumes there's a 'user_id' foreign key in the posts table
    return $this->db->query("SELECT * FROM posts WHERE user_id = ?", [$this->id]);
}

// Many-to-one relationship
public function author()
{
    // This assumes there's an 'author_id' foreign key in this model's table
    $authorModel = new Author();
    return $authorModel->find($this->author_id);
}
```

## Best Practices

1. Keep models focused on a single entity
2. Use descriptive method names
3. Add custom methods for complex queries
4. Keep your models lean and focused on data operations
5. Use validation to ensure data integrity
6. Document your model's properties and methods
7. Consider adding type hints for method parameters and return values