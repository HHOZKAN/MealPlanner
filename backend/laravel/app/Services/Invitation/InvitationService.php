<?php

namespace App\Services\Invitation;

use App\Contracts\Services\InvitationServiceInterface;
use App\Models\Participant;
use App\Models\ShareableInvitationLink;
use App\Models\Event;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class InvitationService implements InvitationServiceInterface
{
    public function acceptInvitation(string $token): ?Participant
    {
        try {
            $userId = Auth::id();
            Log::info('acceptInvitation called', ['user_id' => $userId, 'token' => $token]);

            $shareableLink = $this->findValidShareableLink($token);
            
            if (!$shareableLink) {
                Log::warning('Invitation invalide ou expirée', ['token' => $token]);
                return null;
            }

            $event = $shareableLink->event;
            Log::info('Event found for shareable link', ['event_id' => $event->id]);

            // Check if user is already participant
            $existingParticipant = $this->findExistingParticipant($event, $userId);
            if ($existingParticipant) {
                Log::info('Utilisateur déjà participant de l\'événement', [
                    'user_id' => $userId,
                    'event_id' => $event->id
                ]);
                return $existingParticipant;
            }

            // Add user as participant
            $participant = $this->createParticipant($event, $userId);
            
            Log::info('Invitation acceptée avec succès', [
                'participant_id' => $participant->id,
                'user_id' => $userId,
                'event_id' => $event->id
            ]);

            return $participant;
        } catch (\Exception $e) {
            Log::error('Erreur lors de l\'acceptation de l\'invitation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return null;
        }
    }

    public function createShareableLink(int $eventId, ?string $expiresAt = null): string
    {
        $token = Str::random(32);
        
        ShareableInvitationLink::create([
            'event_id' => $eventId,
            'token' => $token,
            'expires_at' => $expiresAt ? new \DateTime($expiresAt) : null,
            'created_by' => Auth::id(),
        ]);

        return $token;
    }

    public function validateToken(string $token): bool
    {
        return $this->findValidShareableLink($token) !== null;
    }

    public function revokeToken(string $token): bool
    {
        $shareableLink = ShareableInvitationLink::where('token', $token)->first();
        
        if ($shareableLink) {
            return $shareableLink->delete();
        }
        
        return false;
    }

    private function findValidShareableLink(string $token): ?ShareableInvitationLink
    {
        return ShareableInvitationLink::where('token', $token)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                      ->orWhere('expires_at', '>', now());
            })
            ->first();
    }

    private function findExistingParticipant(Event $event, int $userId): ?Participant
    {
        return $event->participants()->where('user_id', $userId)->first();
    }

    private function createParticipant(Event $event, int $userId): Participant
    {
        return $event->participants()->create([
            'user_id' => $userId,
            'status' => 'accepted',
        ]);
    }
}
