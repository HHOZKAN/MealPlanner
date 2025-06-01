<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ShareableInvitationLink extends Model
{
    use HasFactory;

    protected $fillable = [
        'event_id',
        'token',
        'expires_at',
    ];

    protected $dates = [
        'expires_at',
    ];

    /**
     * Get the event that owns the shareable invitation link.
     */
    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }
}
