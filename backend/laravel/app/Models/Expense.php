<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Expense extends Model
{
    use HasFactory;

    protected $fillable = [
        'event_id',
        'ingredient_id',
        'payer_id',
        'amount',
        'description',
        'category',
        'receipt_image'
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function event()
    {
        return $this->belongsTo(Event::class);
    }

    public function ingredient()
    {
        return $this->belongsTo(Ingredient::class);
    }

    public function paidBy()
    {
        return $this->belongsTo(User::class, 'payer_id');
    }

    public function shares()
    {
        return $this->hasMany(ExpenseShare::class);
    }

    /**
     * Get the payer name for API responses
     */
    public function getPayerNameAttribute()
    {
        return $this->paidBy ? $this->paidBy->name : 'Inconnu';
    }

    /**
     * Get the ingredient name for API responses
     */
    public function getIngredientNameAttribute()
    {
        return $this->ingredient ? $this->ingredient->name : 'Ingrédient inconnu';
    }

    /**
     * Get shares as a formatted array for API responses
     */
    public function getSharesFormattedAttribute()
    {
        return $this->shares()->get()->mapWithKeys(function ($share) {
            return [(string)$share->user_id => (float)$share->amount];
        })->toArray();
    }
}
