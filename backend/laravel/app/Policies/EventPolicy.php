<?php

namespace App\Policies;

use App\Models\Event;
use App\Models\User;
use Illuminate\Auth\Access\Response;

namespace App\Policies;

use App\Models\Event;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class EventPolicy
{
    use HandlesAuthorization;

    public function view(User $user, Event $event)
    {
        return $user->id === $event->organizer_id || $event->participants()->where('user_id', $user->id)->exists();
    }

    public function update(User $user, Event $event)
    {
        return $user->id === $event->organizer_id;
    }

    public function delete(User $user, Event $event)
    {
        return $user->id === $event->organizer_id;
    }
}