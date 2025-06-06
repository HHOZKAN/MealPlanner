<?php

namespace App\Http\Controllers\Api\Participant;

use App\Http\Controllers\Controller;
use App\Contracts\Services\ParticipantServiceInterface;
use App\DTOs\Participant\InvitationData;
use App\Models\Event;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Contrôleur spécialisé pour la gestion des invitations
 * Responsabilités :
 * - Inviter des participants par pseudo (sans email)
 * - Générer des liens d'invitation partageables
 * - Gérer les invitations en attente
 */
class InvitationController extends Controller
{
    use ApiResponse;

    public function __construct(
        private ParticipantServiceInterface $participantService
    ) {}

    /**
     * Invite un participant à un événement via un pseudo
     * 
     * Cette méthode permet d'inviter quelqu'un qui n'a pas encore de compte
     * en utilisant simplement un pseudo. L'invitation sera en attente jusqu'à
     * ce que la personne s'inscrive et accepte l'invitation.
     * 
     * @param Request $request
     * @param Event $event L'événement pour lequel inviter
     * @return \Illuminate\Http\JsonResponse
     */
    public function invite(Request $request, Event $event)
    {
        try {
            $validated = $request->validate([
                'nickname' => 'required|string|max:255',
                'message' => 'nullable|string|max:1000'
            ]);

            $invitationData = InvitationData::fromRequest($validated);
            $pendingParticipant = $this->participantService->inviteParticipant($event, $invitationData);

            return $this->successResponse([
                'pending_participant' => $pendingParticipant,
                'type' => 'nickname'
            ], 'Invitation créée avec succès');

        } catch (\Exception $e) {
            Log::error('Erreur lors de l\'invitation:', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->errorResponse(
                'Erreur lors de l\'envoi de l\'invitation: ' . $e->getMessage(), 
                $e->getMessage() === 'Ce pseudo est déjà invité' ? 422 : 500
            );
        }
    }

    /**
     * Génère un lien d'invitation partageable pour un événement
     * 
     * Ce lien peut être partagé sur les réseaux sociaux, par message, etc.
     * Il permet à n'importe qui de rejoindre l'événement en s'inscrivant.
     * Le lien expire après 30 jours par défaut.
     * 
     * @param Request $request
     * @param Event $event L'événement pour lequel générer le lien
     * @return \Illuminate\Http\JsonResponse
     */
    public function generateShareableLink(Request $request, Event $event)
    {
        try {
            $validated = $request->validate([
                'expires_in_days' => 'nullable|integer|min:1|max:365'
            ]);

            $expiresInDays = $validated['expires_in_days'] ?? 30;
            $shareableLink = $this->participantService->generateShareableLink($event, $expiresInDays);

            return $this->successResponse([
                'shareable_link' => $shareableLink,
                'expires_in_days' => $expiresInDays
            ], 'Lien partageable généré avec succès');

        } catch (\Exception $e) {
            Log::error('Erreur lors de la génération du lien partageable', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->errorResponse(
                'Erreur lors de la génération du lien partageable: ' . $e->getMessage(), 
                $e->getMessage() === 'Seul l\'organisateur peut générer un lien partageable' ? 403 : 500
            );
        }
    }

    /**
     * Valide un token d'invitation sans l'accepter
     * 
     * Permet de vérifier si un token d'invitation est valide
     * avant que l'utilisateur ne s'inscrive ou ne se connecte
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function validateToken(Request $request)
    {
        try {
            $validated = $request->validate([
                'token' => 'required|string'
            ]);

            $shareableLink = \App\Models\ShareableInvitationLink::where('token', $validated['token'])
                ->where(function ($query) {
                    $query->whereNull('expires_at')
                          ->orWhere('expires_at', '>', now());
                })
                ->with('event:id,title,date,location,type')
                ->first();

            if ($shareableLink) {
                return $this->successResponse([
                    'valid' => true,
                    'event' => $shareableLink->event,
                    'expires_at' => $shareableLink->expires_at
                ], 'Token valide');
            } else {
                return $this->successResponse([
                    'valid' => false
                ], 'Token invalide ou expiré');
            }

        } catch (\Exception $e) {
            Log::error('Erreur lors de la validation du token', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->errorResponse(
                'Erreur lors de la validation du token: ' . $e->getMessage(), 
                500
            );
        }
    }
}
