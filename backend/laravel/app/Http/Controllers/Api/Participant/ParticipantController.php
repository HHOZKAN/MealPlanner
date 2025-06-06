<?php

namespace App\Http\Controllers\Api\Participant;

use App\Http\Controllers\Controller;
use App\Contracts\Services\ParticipantServiceInterface;
use App\DTOs\Participant\ResponseData;
use App\Models\Event;
use App\Models\Participant;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

/**
 * Contrôleur pour la gestion basique des participants
 * Responsabilités :
 * - Lister les participants d'un événement
 * - Gérer les réponses aux invitations (accepter/refuser)
 * - Supprimer des participants
 */
class ParticipantController extends Controller
{
    use ApiResponse;

    public function __construct(
        private ParticipantServiceInterface $participantService
    ) {}

    /**
     * Liste des participants d'un événement
     * 
     * Retourne :
     * - participants : Liste des participants confirmés avec leurs informations utilisateur
     * - pending_invitations : Invitations par email en attente
     * - pending_participants : Participants invités par pseudo en attente
     * 
     * @param Event $event L'événement concerné
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Event $event)
    {
        try {
            if (!$this->participantService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $data = $this->participantService->listParticipants($event);

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
     * Traite la réponse d'un participant à une invitation
     * 
     * Statuts possibles : accepted, declined, maybe
     * Permet d'ajouter une note optionnelle
     * 
     * @param Request $request
     * @param Participant $participant
     * @return \Illuminate\Http\JsonResponse
     */
    public function respond(Request $request, Participant $participant)
    {
        try {
            $validated = $request->validate([
                'status' => 'required|in:accepted,declined,maybe',
                'note' => 'nullable|string'
            ]);

            $responseData = ResponseData::fromRequest($validated);
            $updatedParticipant = $this->participantService->handleInvitationResponse(
                $participant, 
                $responseData
            );

            return $this->successResponse(
                $updatedParticipant, 
                'Réponse enregistrée avec succès'
            );
        } catch (\Exception $e) {
            Log::error('Erreur lors de la réponse à l\'invitation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse(
                'Erreur lors de la réponse à l\'invitation: ' . $e->getMessage(), 
                500
            );
        }
    }

    /**
     * Supprime un participant d'un événement
     * 
     * Seuls l'organisateur de l'événement ou le participant lui-même
     * peuvent effectuer cette action
     * 
     * @param Participant $participant
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Participant $participant)
    {
        try {
            $this->participantService->removeParticipant($participant);

            return $this->successResponse(null, 'Participant retiré avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression du participant', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse(
                'Erreur lors du retrait du participant: ' . $e->getMessage(), 
                500
            );
        }
    }

    /**
     * Accepte une invitation via un token de lien partageable
     * 
     * Utilisé quand un utilisateur clique sur un lien d'invitation partageable
     * Crée automatiquement un participant avec le statut "accepted"
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function acceptInvitation(Request $request)
    {
        try {
            $validated = $request->validate([
                'token' => 'required|string'
            ]);

            $participant = $this->participantService->acceptShareableInvitation(
                $validated['token'], 
                Auth::id()
            );

            if ($participant) {
                return $this->successResponse(
                    $participant->load('user'), 
                    'Invitation acceptée avec succès'
                );
            } else {
                return $this->errorResponse('Invitation invalide ou expirée', 404);
            }
        } catch (\Exception $e) {
            Log::error('Erreur lors de l\'acceptation de l\'invitation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse(
                'Erreur lors de l\'acceptation de l\'invitation: ' . $e->getMessage(), 
                500
            );
        }
    }
}
