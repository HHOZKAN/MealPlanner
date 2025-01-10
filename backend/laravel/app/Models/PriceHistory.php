<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PriceHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_name',
        'store_name',
        'price',
        'unit',
        'price_date',
        'source'
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'price_date' => 'date'
    ];
}
