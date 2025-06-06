<?php

namespace App\Services;

use App\Contracts\Services\ParticipantServiceInterface;
use App\DTOs\Participant\InvitationData;
use App\DTOs\Participant\ResponseData;
use App\Models\Event;
use App\Models\Participant;
use App\Models\ShareableInvitationLink;
use App\ValueObjects\ParticipantStatus;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class ParticipantService implements ParticipantServiceInterface
{
    /**
     * {@inheritdoc}
     */
    public function listParticipants(Event $event): array
    {
        return [
            'participants' => $event->participants()->with('user')->get(),
            'pending_invitations' => $event->pendingInvitations,
            'pending_participants' => $event->pendingParticipants,
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function generateShareableLink(Event $event, ?int $expiresInDays = 30): string
    {
        if ($event->organizer_id !== Auth::id()) {
            throw new \Exception('Seul l\'organisateur peut générer un lien partageable');
        }

        $existingLink = ShareableInvitationLink::where('event_id', $event->id)
            ->where(function ($query) {
                $query->whereNull('expires_at')
                      ->orWhere('expires_at', '>', now());
            })
            ->first();

        if ($existingLink) {
            $token = $existingLink->token;
        } else {
            $token = Str::random(32);
            $expiresAt = now()->addDays($expiresInDays);

            ShareableInvitationLink::create([
                'event_id' => $event->id,
                'token' => $token,
                'expires_at' => $expiresAt,
            ]);
        }

        $frontendUrl = config('app.frontend_url', 'http://localhost:3000');
        return $frontendUrl . '/register?event_id=' . $event->id . '&token=' . $token;
    }

    /**
     * {@inheritdoc}
     */
    public function inviteParticipant(Event $event, InvitationData $data): mixed
    {
        if ($event->organizer_id !== Auth::id()) {
            throw new \Exception('Seul l\'organisateur peut inviter des participants');
        }

        if (empty($data->nickname)) {
            throw new \Exception('Pseudo requis');
        }

        $existingPendingParticipant = $event->pendingParticipants()
            ->where('nickname', $data->nickname)
            ->first();

        if ($existingPendingParticipant) {
            throw new \Exception('Ce pseudo est déjà invité');
        }

        $pendingParticipant = $event->pendingParticipants()->create([
            'nickname' => $data->nickname,
            'message' => $data->message,
            'status' => ParticipantStatus::PENDING->value,
        ]);

        Log::info('Invitation créée avec pseudo', [
            'nickname' => $data->nickname,
            'event_id' => $event->id,
        ]);

        return $pendingParticipant;
    }

    /**
     * {@inheritdoc}
     */
    public function handleInvitationResponse(Participant $participant, ResponseData $data): Participant
    {
        if ($participant->user_id !== Auth::id()) {
            throw new \Exception('Non autorisé');
        }

        $participant->update([
            'status' => $data->status,
            'note' => $data->note,
            'responded_at' => now(),
        ]);

        Log::info('Réponse à l\'invitation mise à jour', [
            'participant_id' => $participant->id,
            'status' => $data->status,
        ]);

        return $participant->load('user');
    }

    /**
     * {@inheritdoc}
     */
    public function removeParticipant(Participant $participant): bool
    {
        if (!$this->canManageParticipant($participant, Auth::id())) {
            throw new \Exception('Non autorisé');
        }

        $participant->delete();

        Log::info('Participant supprimé', [
            'participant_id' => $participant->id,
            'event_id' => $participant->event_id,
        ]);

        return true;
    }

    /**
     * {@inheritdoc}
     */
    public function acceptShareableInvitation(string $token, int $userId): ?Participant
    {
        try {
            $shareableLink = ShareableInvitationLink::where('token', $token)
                ->where(function ($query) {
                    $query->whereNull('expires_at')
                          ->orWhere('expires_at', '>', now());
                })
                ->first();

            if (!$shareableLink) {
                Log::warning('Invitation invalide ou expirée', ['token' => $token]);
                return null;
            }

            $event = $shareableLink->event;

            $existingParticipant = $event->participants()->where('user_id', $userId)->first();
            if ($existingParticipant) {
                Log::info('Utilisateur déjà participant de l\'événement', [
                    'user_id' => $userId,
                    'event_id' => $event->id,
                ]);
                return $existingParticipant;
            }

            $participant = $event->participants()->create([
                'user_id' => $userId,
                'status' => ParticipantStatus::ACCEPTED->value,
            ]);

            Log::info('Invitation acceptée avec succès', [
                'participant_id' => $participant->id,
                'user_id' => $userId,
                'event_id' => $event->id,
            ]);

            return $participant;
        } catch (\Exception $e) {
            Log::error('Erreur lors de l\'acceptation de l\'invitation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return null;
        }
    }

    /**
     * {@inheritdoc}
     */
    public function canAccessEvent(Event $event, int $userId): bool
    {
        return $event->organizer_id === $userId ||
            $event->participants()->where('user_id', $userId)->exists();
    }

    /**
     * {@inheritdoc}
     */
    public function canManageParticipant(Participant $participant, int $userId): bool
    {
        return $participant->event->organizer_id === $userId ||
            $participant->user_id === $userId;
    }
}
