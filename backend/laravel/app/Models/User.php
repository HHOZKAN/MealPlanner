<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL; 


class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'phone_number',
        'avatar',
        'preferences',
        'is_active'
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'preferences' => 'array',
         'is_active' => 'boolean'
    ];

    protected $appends = ['avatar_url'];
    public function getAvatarUrlAttribute()
    {
        if ($this->avatar) {
            return URL::to('storage/' . $this->avatar);
        }
        return null;
    }

    // Relations
    public function organizedEvents()
    {
        return $this->hasMany(Event::class, 'organizer_id');
    }

    public function participatedEvents()
    {
        return $this->belongsToMany(Event::class, 'participants')
            ->withPivot('status', 'responded_at', 'note')
            ->withTimestamps();
    }

    public function assignedIngredients()
    {
        return $this->hasMany(IngredientAssignment::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'payer_id');
    }

    public function receivedPayments()
    {
        return $this->hasMany(Payment::class, 'receiver_id');
    }

    
}
