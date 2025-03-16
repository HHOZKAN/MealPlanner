<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\User;
use App\Models\Participant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str; // Ajout de l'import pour Str
use App\Traits\ApiResponse;

class ParticipantController extends Controller
{
    use ApiResponse;

    /**
     * Vérifier si l'utilisateur peut accéder à l'événement
     */
    private function canAccessEvent(Event $event)
    {
        return $event->organizer_id === Auth::id() || 
               $event->participants()->where('user_id', Auth::id())->exists();
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

            // Valider l'email
            $validated = $request->validate([
                'email' => 'required|email',
                'message' => 'nullable|string'
            ]);

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

                return $this->successResponse([
                    'participant' => $participant->load('user'),
                    'type' => 'existing_user'
                ], 'Invitation envoyée avec succès');
            } else {
                // Stocker l'invitation en attente
                $pendingInvitation = $event->pendingInvitations()->create([
                    'email' => $validated['email'],
                    'message' => $validated['message'] ?? null,
                    'token' => Str::random(32)
                ]);

                return $this->successResponse([
                    'invitation' => $pendingInvitation,
                    'type' => 'new_user'
                ], 'Invitation envoyée par email');
            }
        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de l\'envoi de l\'invitation: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Liste des participants
     */
    public function index(Event $event)
    {
        try {
            if (!$this->canAccessEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $data = [
                'participants' => $event->participants()->with('user')->get(),
                'pending_invitations' => $event->pendingInvitations
            ];

            return $this->successResponse($data, 'Participants récupérés avec succès');
        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de la récupération des participants', 500);
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

            return $this->successResponse(
                $participant->load('user'), 
                'Réponse enregistrée avec succès'
            );
        } catch (\Exception $e) {
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
            return $this->successResponse(null, 'Participant retiré avec succès');
        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors du retrait du participant', 500);
        }
    }

    /**
     * Vérifier si l'utilisateur peut gérer ce participant
     */
    private function canManageParticipant(Participant $participant)
    {
        return $participant->event->organizer_id === Auth::id() || 
               $participant->user_id === Auth::id();
    }
}