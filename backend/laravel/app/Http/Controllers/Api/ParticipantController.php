<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\User;
use App\Models\Participant;
use App\Models\PendingParticipant;
use App\Mail\EventInvitation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use App\Traits\ApiResponse;

class ParticipantController extends Controller
{
    use ApiResponse;

    /**
     * Liste des participants d'un événement
     */
    public function index(Event $event)
    {
        try {
            if (!$this->canAccessEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $data = [
                'participants' => $event->participants()->with('user')->get(),
                'pending_invitations' => $event->pendingInvitations,
                'pending_participants' => $event->pendingParticipants
            ];

            return $this->successResponse($data, 'Participants récupérés avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des participants', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la récupération des participants', 500);
        }
    }

    /**
     * Générer un lien d'invitation partageable pour un événement
     */
    public function generateShareableLink(Event $event)
    {
        try {
            if ($event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Seul l\'organisateur peut générer un lien partageable', 403);
            }

            // Check if a shareable link already exists for the event and is not expired
            $existingLink = \App\Models\ShareableInvitationLink::where('event_id', $event->id)
                ->where(function ($query) {
                    $query->whereNull('expires_at')
                          ->orWhere('expires_at', '>', now());
                })
                ->first();

            if ($existingLink) {
                $token = $existingLink->token;
            } else {
                // Create a new shareable link with expiration (e.g., 30 days)
                $token = Str::random(32);
                $expiresAt = now()->addDays(30);

                $newLink = \App\Models\ShareableInvitationLink::create([
                    'event_id' => $event->id,
                    'token' => $token,
                    'expires_at' => $expiresAt,
                ]);
            }

            // Construct the shareable URL (frontend URL with token as query param)
            $frontendUrl = config('app.frontend_url', 'http://localhost:3000');
            $shareableLink = $frontendUrl . '/register?event_id=' . $event->id . '&token=' . $token;

            return $this->successResponse(['shareable_link' => $shareableLink], 'Lien partageable généré avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la génération du lien partageable', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la génération du lien partageable', 500);
        }
    }

    /**
     * Inviter des participants
     */
    public function invite(Request $request, Event $event)
    {
        try {
            // Vérifier que c'est bien l'organisateur qui invite
            if ($event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Seul l\'organisateur peut inviter des participants', 403);
            }

            // Valider les données
            $validated = $request->validate([
                'email' => 'required_without:nickname|email|nullable',
                'nickname' => 'required_without:email|string|nullable',
                'message' => 'nullable|string'
            ]);

            // Si un email est fourni, utiliser le processus d'invitation par email
            if (!empty($validated['email'])) {
                // Vérifier si l'utilisateur existe déjà
                $user = User::where('email', $validated['email'])->first();

                if ($user) {
                    // Vérifier si l'utilisateur n'est pas déjà invité
                    $existingParticipant = $event->participants()
                        ->where('user_id', $user->id)
                        ->first();

                    if ($existingParticipant) {
                        return $this->errorResponse('Cet utilisateur est déjà invité', 422);
                    }

                    // Créer la participation
                    $participant = $event->participants()->create([
                        'user_id' => $user->id,
                        'status' => 'pending'
                    ]);

                    // Envoyer l'email d'invitation
                    Mail::to($user->email)
                        ->queue(new EventInvitation(
                            $event,
                            $validated['message'] ?? null,
                            false
                        ));

                    Log::info('Invitation envoyée à un utilisateur existant', [
                        'user_id' => $user->id,
                        'event_id' => $event->id
                    ]);

                    return $this->successResponse([
                        'participant' => $participant->load('user'),
                        'type' => 'existing_user'
                    ], 'Invitation envoyée avec succès');
                } else {
                    // Créer une invitation en attente pour un nouvel utilisateur
                    $token = Str::random(32);
                    $pendingInvitation = $event->pendingInvitations()->create([
                        'email' => $validated['email'],
                        'message' => $validated['message'] ?? null,
                        'token' => $token
                    ]);

                    // Envoyer l'email d'invitation
                    Mail::to($validated['email'])
                        ->queue(new EventInvitation(
                            $event,
                            $validated['message'] ?? null,
                            true,
                            $token
                        ));

                    Log::info('Invitation envoyée à un nouvel utilisateur', [
                        'email' => $validated['email'],
                        'event_id' => $event->id
                    ]);

                    return $this->successResponse([
                        'invitation' => $pendingInvitation,
                        'type' => 'new_user'
                    ], 'Invitation envoyée par email');
                }
            }
            // Si un pseudo est fourni, créer une invitation en attente avec pseudo
            else if (!empty($validated['nickname'])) {
                // Vérifier si le pseudo n'est pas déjà invité
                $existingPendingParticipant = $event->pendingParticipants()
                    ->where('nickname', $validated['nickname'])
                    ->first();

                if ($existingPendingParticipant) {
                    return $this->errorResponse('Ce pseudo est déjà invité', 422);
                }

                // Créer l'invitation en attente
                $pendingParticipant = $event->pendingParticipants()->create([
                    'nickname' => $validated['nickname'],
                    'message' => $validated['message'] ?? null,
                    'status' => 'pending'
                ]);

                Log::info('Invitation créée avec pseudo', [
                    'nickname' => $validated['nickname'],
                    'event_id' => $event->id
                ]);

                return $this->successResponse([
                    'pending_participant' => $pendingParticipant,
                    'type' => 'nickname'
                ], 'Invitation créée avec succès');
            }

            return $this->errorResponse('Email ou pseudo requis', 422);

        } catch (\Exception $e) {
            Log::error('Erreur lors de l\'invitation:', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->errorResponse(
                'Erreur lors de l\'envoi de l\'invitation: ' . $e->getMessage(), 
                500
            );
        }
    }

    /**
     * Répondre à une invitation
     */
    public function respond(Request $request, Participant $participant)
    {
        try {
            if ($participant->user_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'status' => 'required|in:accepted,declined,maybe',
                'note' => 'nullable|string'
            ]);

            $participant->update([
                'status' => $validated['status'],
                'note' => $validated['note'],
                'responded_at' => now()
            ]);

            Log::info('Réponse à l\'invitation mise à jour', [
                'participant_id' => $participant->id,
                'status' => $validated['status']
            ]);

            return $this->successResponse(
                $participant->load('user'), 
                'Réponse enregistrée avec succès'
            );
        } catch (\Exception $e) {
            Log::error('Erreur lors de la réponse à l\'invitation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la réponse à l\'invitation', 500);
        }
    }

    /**
     * Supprimer un participant
     */
    public function destroy(Participant $participant)
    {
        try {
            if (!$this->canManageParticipant($participant)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $participant->delete();

            Log::info('Participant supprimé', [
                'participant_id' => $participant->id,
                'event_id' => $participant->event_id
            ]);

            return $this->successResponse(null, 'Participant retiré avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression du participant', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du retrait du participant', 500);
        }
    }

    /**
     * Vérifier si l'utilisateur peut accéder à l'événement
     */
    private function canAccessEvent(Event $event)
    {
        return $event->organizer_id === Auth::id() || 
               $event->participants()->where('user_id', Auth::id())->exists();
    }

    /**
     * Vérifier si l'utilisateur peut gérer ce participant
     */
    private function canManageParticipant(Participant $participant)
    {
        return $participant->event->organizer_id === Auth::id() || 
               $participant->user_id === Auth::id();
    }

    /**
     * Valider un token d'invitation et associer l'utilisateur à l'événement
     */
    public function acceptInvitation(Request $request)
    {
        try {
            $validated = $request->validate([
                'token' => 'required|string',
            ]);

            $token = $validated['token'];
            $userId = Auth::id();

            // Chercher l'invitation en attente par token
            $pendingInvitation = \App\Models\PendingInvitation::where('token', $token)->first();

            if (!$pendingInvitation) {
                return $this->errorResponse('Invitation invalide ou expirée', 404);
            }

            $event = $pendingInvitation->event;

            // Vérifier si l'utilisateur est déjà participant
            $existingParticipant = $event->participants()->where('user_id', $userId)->first();
            if ($existingParticipant) {
                return $this->successResponse($existingParticipant, 'Vous êtes déjà participant de cet événement');
            }

            // Ajouter l'utilisateur comme participant
            $participant = $event->participants()->create([
                'user_id' => $userId,
                'status' => 'accepted',
            ]);

            // Supprimer l'invitation en attente
            $pendingInvitation->delete();

            return $this->successResponse($participant->load('user'), 'Invitation acceptée avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de l\'acceptation de l\'invitation:', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de l\'acceptation de l\'invitation', 500);
        }
    }
}
