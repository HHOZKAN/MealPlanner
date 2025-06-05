<?php

namespace App\Repositories;

use App\Contracts\Repositories\EventRepositoryInterface;
use App\Models\Event;
use Illuminate\Database\Eloquent\Collection;

class EventRepository implements EventRepositoryInterface
{
    public function getEventsForUser(int $userId): Collection
    {
        return Event::with(['organizer'])
            ->where('organizer_id', $userId)
            ->orWhereHas('participants', function ($query) use ($userId) {
                $query->where('user_id', $userId);
            })
            ->latest()
            ->get();
    }

    public function create(array $data): Event
    {
        return Event::create($data);
    }

    public function findById(int $id): ?Event
    {
        return Event::find($id);
    }

    public function update(Event $event, array $data): Event
    {
        $event->update($data);
        return $event->fresh();
    }

    public function delete(Event $event): bool
    {
        return $event->delete();
    }

    public function getTrashedEventsForUser(int $userId): Collection
    {
        return Event::onlyTrashed()
            ->where('organizer_id', $userId)
            ->latest()
            ->get();
    }

    public function restore(int $id): ?Event
    {
        $event = Event::onlyTrashed()->find($id);
        
        if ($event) {
            $event->restore();
            return $event;
        }
        
        return null;
    }

    public function forceDelete(int $id): bool
    {
        $event = Event::withTrashed()->find($id);
        
        if ($event) {
            return $event->forceDelete();
        }
        
        return false;
    }

    public function canUserAccessEvent(Event $event, int $userId): bool
    {
        return $event->organizer_id === $userId ||
            $event->participants()->where('user_id', $userId)->exists();
    }
}
