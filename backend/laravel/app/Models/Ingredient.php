<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Ingredient extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'event_id',
        'name',
        'quantity',
        'unit',
        'estimated_price',
        'actual_price',
        'is_required',
        'added_by',
        'status'
    ];

    protected $casts = [
        'is_required' => 'boolean',
        'estimated_price' => 'decimal:2',
        'actual_price' => 'decimal:2'
    ];

    public function event()
    {
        return $this->belongsTo(Event::class);
    }

    public function addedBy()
    {
        return $this->belongsTo(User::class, 'added_by');
    }

    public function assignments()
    {
        return $this->hasMany(IngredientAssignment::class);
    }

    public function sharedIngredients()
    {
        return $this->hasMany(SharedIngredient::class);
    }
}
