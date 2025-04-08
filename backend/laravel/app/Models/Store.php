<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Store extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'website',
        'api_key',
        'is_active'
    ];

    protected $casts = [
        'is_active' => 'boolean'
    ];

    public function priceHistories()
    {
        return $this->hasMany(PriceHistory::class);
    }
}