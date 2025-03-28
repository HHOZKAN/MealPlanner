<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class IngredientAssignment extends Model
{
    use HasFactory;

    protected $fillable = [
        'ingredient_id',
        'user_id',
        'quantity',
        'price_paid',
        'store_name',
        'receipt_image',
        'status'
    ];

    protected $casts = [
        'quantity' => 'decimal:2',
        'price_paid' => 'decimal:2'
    ];

    public const STATUS_PENDING = 'pending';
    public const STATUS_PURCHASED = 'purchased';

    public static $validStatuses = [
        self::STATUS_PENDING,
        self::STATUS_PURCHASED
    ];

    public function ingredient()
    {
        return $this->belongsTo(Ingredient::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}