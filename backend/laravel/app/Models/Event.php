<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Event extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'title',
        'description',
        'date',
        'location',
        'type',
        'organizer_id',
        'status'
    ];

    protected $casts = [
        'date' => 'datetime'
    ];

    public function organizer()
    {
        return $this->belongsTo(User::class, 'organizer_id');
    }

    public function participants()
    {
        return $this->hasMany(Participant::class);
    }

    public function ingredients()
    {
        return $this->hasMany(Ingredient::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }

    public function getIsUpcomingAttribute()
    {
        return $this->date->isFuture();
    }

    public function getTotalCostAttribute()
    {
        return $this->ingredients()
            ->whereNotNull('actual_price')
            ->sum('actual_price');
    }

    public function pendingInvitations()
    {
        return $this->hasMany(PendingInvitation::class);
    }
}
