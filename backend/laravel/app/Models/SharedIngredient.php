<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SharedIngredient extends Model
{
    use HasFactory;

    protected $fillable = [
        'ingredient_id',
        'event_id',
        'user_id',
        'shared_with_user_id',
        'share_percentage'
    ];

    protected $casts = [
        'share_percentage' => 'decimal:2'
    ];

    public function ingredient()
    {
        return $this->belongsTo(Ingredient::class);
    }

    public function event()
    {
        return $this->belongsTo(Event::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function sharedWithUser()
    {
        return $this->belongsTo(User::class, 'shared_with_user_id');
    }
}
