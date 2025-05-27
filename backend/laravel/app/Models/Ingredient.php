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
        'added_by',
        'status',
        'notes',
        'emoji'
    ];

    protected $casts = [
        'quantity' => 'decimal:2',
        'estimated_price' => 'decimal:2',
        'actual_price' => 'decimal:2',
    ];

    const STATUS_NEEDED = 'needed';
    const STATUS_ASSIGNED = 'assigned';
    const STATUS_PURCHASED = 'purchased';

    const UNITS = [
        'g' => 'Grammes',
        'kg' => 'Kilogrammes',
        'ml' => 'Millilitres',
        'l' => 'Litres',
        'piece' => 'Pièce(s)',
        'pack' => 'Paquet(s)'
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
}