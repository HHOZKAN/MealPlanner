<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GroupPreference extends Model
{
    use HasFactory;

    protected $fillable = [
        'group_id',
        'key',
        'value'
    ];

    public function group()
    {
        return $this->belongsTo(Group::class);
    }
}