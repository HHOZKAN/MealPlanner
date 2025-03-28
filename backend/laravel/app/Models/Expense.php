<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Expense extends Model
{
    use HasFactory;

    protected $fillable = [
        'event_id',
        'paid_by',
        'amount',
        'description',
        'receipt_image'
    ];

    public function event()
    {
        return $this->belongsTo(Event::class);
    }

    public function paidBy()
    {
        return $this->belongsTo(User::class, 'paid_by');
    }

    public function shares()
    {
        return $this->hasMany(ExpenseShare::class);
    }
}