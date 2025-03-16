<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PendingInvitation extends Model
{
    use HasFactory;

    protected $fillable = [
        'event_id',
        'email',
        'token',
        'message',
        'accepted_at'
    ];

    protected $casts = [
        'accepted_at' => 'datetime'
    ];

    /**
     * Get the event that owns the invitation.
     */
    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }
}