<?php

namespace App\Contracts\Services;

use App\Models\Participant;

interface InvitationServiceInterface
{
    /**
     * Accept an invitation using a token
     */
    public function acceptInvitation(string $token): ?Participant;

    /**
     * Create a shareable invitation link
     */
    public function createShareableLink(int $eventId, ?string $expiresAt = null): string;

    /**
     * Validate invitation token
     */
    public function validateToken(string $token): bool;

    /**
     * Revoke invitation token
     */
    public function revokeToken(string $token): bool;
}
