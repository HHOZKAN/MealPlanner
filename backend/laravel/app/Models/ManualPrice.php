<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ManualPrice extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_name',
        'price',
        'store_name',
        'added_by',
        'receipt_image',
        'notes'
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'added_by');
    }
}