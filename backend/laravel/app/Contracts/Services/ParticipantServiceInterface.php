<?php

namespace App\Contracts\Services;

use App\Models\Event;
use App\Models\Participant;
use App\DTOs\Participant\InvitationData;
use App\DTOs\Participant\ResponseData;
use Illuminate\Support\Collection;

interface ParticipantServiceInterface
{
    /**
     * Récupère la liste des participants d'un événement
     * Inclut les participants confirmés, en attente et les invitations en cours
     *
     * @param Event $event L'événement concerné
     * @return array{
     *  participants: Collection,
     *  pending_invitations: Collection,
     *  pending_participants: Collection
     * }
     */
    public function listParticipants(Event $event): array;

    /**
     * Génère un lien d'invitation partageable pour un événement
     * Le lien expire après 30 jours par défaut
     *
     * @param Event $event L'événement pour lequel générer le lien
     * @param int|null $expiresInDays Nombre de jours avant expiration (30 par défaut)
     * @return string L'URL complète du lien d'invitation
     */
    public function generateShareableLink(Event $event, ?int $expiresInDays = 30): string;

    /**
     * Invite un participant à un événement via un pseudo
     * Utilisé pour les invitations sans email (participants non-inscrits)
     *
     * @param Event $event L'événement concerné
     * @param InvitationData $data Les données d'invitation
     * @return mixed Le participant en attente créé
     */
    public function inviteParticipant(Event $event, InvitationData $data): mixed;

    /**
     * Traite la réponse d'un participant à une invitation
     *
     * @param Participant $participant Le participant qui répond
     * @param ResponseData $data Les données de réponse (accepted/declined/maybe)
     * @return Participant Le participant mis à jour
     */
    public function handleInvitationResponse(Participant $participant, ResponseData $data): Participant;

    /**
     * Supprime un participant d'un événement
     *
     * @param Participant $participant Le participant à supprimer
     * @return bool True si la suppression a réussi
     */
    public function removeParticipant(Participant $participant): bool;

    /**
     * Accepte une invitation via un token de lien partageable
     *
     * @param string $token Le token d'invitation
     * @param int $userId L'ID de l'utilisateur qui accepte l'invitation
     * @return Participant|null Le participant créé ou null si le token est invalide
     */
    public function acceptShareableInvitation(string $token, int $userId): ?Participant;

    /**
     * Vérifie si un utilisateur peut accéder à un événement
     *
     * @param Event $event L'événement à vérifier
     * @param int $userId L'ID de l'utilisateur
     * @return bool True si l'utilisateur peut accéder à l'événement
     */
    public function canAccessEvent(Event $event, int $userId): bool;

    /**
     * Vérifie si un utilisateur peut gérer un participant
     *
     * @param Participant $participant Le participant à vérifier
     * @param int $userId L'ID de l'utilisateur
     * @return bool True si l'utilisateur peut gérer le participant
     */
    public function canManageParticipant(Participant $participant, int $userId): bool;
}
