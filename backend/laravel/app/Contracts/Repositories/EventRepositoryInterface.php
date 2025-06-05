<?php

namespace App\Contracts\Repositories;

use App\Models\Event;
use Illuminate\Database\Eloquent\Collection;

interface EventRepositoryInterface
{
    /**
     * Get all events for a user
     */
    public function getEventsForUser(int $userId): Collection;

    /**
     * Create a new event
     */
    public function create(array $data): Event;

    /**
     * Find event by ID
     */
    public function findById(int $id): ?Event;

    /**
     * Update event
     */
    public function update(Event $event, array $data): Event;

    /**
     * Delete event
     */
    public function delete(Event $event): bool;

    /**
     * Get trashed events for user
     */
    public function getTrashedEventsForUser(int $userId): Collection;

    /**
     * Restore event
     */
    public function restore(int $id): ?Event;

    /**
     * Force delete event
     */
    public function forceDelete(int $id): bool;

    /**
     * Check if user can access event
     */
    public function canUserAccessEvent(Event $event, int $userId): bool;
}
