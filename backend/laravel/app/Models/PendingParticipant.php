<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PendingParticipant extends Model
{
    use HasFactory;

    protected $fillable = [
        'event_id',
        'nickname',
        'status',
        'message',
        'responded_at'
    ];

    protected $casts = [
        'responded_at' => 'datetime'
    ];

    public function event()
    {
        return $this->belongsTo(Event::class);
    }
}
