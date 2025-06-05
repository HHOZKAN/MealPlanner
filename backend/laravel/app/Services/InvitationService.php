<?php

namespace App\Services;

use App\Models\PendingInvitation;
use App\Models\Event;
use App\Models\Participant;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class InvitationService
{
    /**
     * Accept an invitation token and associate the authenticated user to the event.
     *
     * @param string $token
     * @return Participant|null
     */
    public function acceptInvitation(string $token)
    {
        try {
            $userId = Auth::id();
            Log::info('acceptInvitation called', ['user_id' => $userId, 'token' => $token]);

            // Check shareable invitation links only (email invitations removed)
            $shareableLink = \App\Models\ShareableInvitationLink::where('token', $token)
                ->where(function ($query) {
                    $query->whereNull('expires_at')
                          ->orWhere('expires_at', '>', now());
                })
                ->first();
            Log::info('ShareableInvitationLink found', ['shareableLink' => $shareableLink]);

            if ($shareableLink) {
                $event = $shareableLink->event;
                Log::info('Event found for shareable link', ['event_id' => $event->id]);

                // Check if user is already participant
                $existingParticipant = $event->participants()->where('user_id', $userId)->first();
                if ($existingParticipant) {
                    Log::info('Utilisateur déjà participant de l\'événement', [
                        'user_id' => $userId,
                        'event_id' => $event->id
                    ]);
                    return $existingParticipant;
                }

                // Add user as participant
                $participant = $event->participants()->create([
                    'user_id' => $userId,
                    'status' => 'accepted',
                ]);
                Log::info('Participant created for shareable link', ['participant_id' => $participant->id]);

                Log::info('Invitation acceptée avec succès (shareable link)', [
                    'participant_id' => $participant->id,
                    'user_id' => $userId,
                    'event_id' => $event->id
                ]);

                return $participant;
            }

            Log::warning('Invitation invalide ou expirée', ['token' => $token]);
            return null;
        } catch (\Exception $e) {
            Log::error('Erreur lors de l\'acceptation de l\'invitation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return null;
        }
    }
}
