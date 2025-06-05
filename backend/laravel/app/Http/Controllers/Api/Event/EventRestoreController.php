<?php

namespace App\Http\Controllers\Api\Event;

use App\Http\Controllers\Controller;
use App\Contracts\Repositories\EventRepositoryInterface;
use App\Traits\ApiResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class EventRestoreController extends Controller
{
    use ApiResponse;

    public function __construct(
        private EventRepositoryInterface $eventRepository
    ) {}

    public function trashed()
    {
        try {
            $events = $this->eventRepository->getTrashedEventsForUser(Auth::id());

            return $this->successResponse(
                $events,
                'Liste des événements supprimés récupérée avec succès'
            );
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des événements supprimés', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse(
                'Erreur lors de la récupération des événements supprimés',
                500
            );
        }
    }

    public function restore(int $id)
    {
        try {
            $event = $this->eventRepository->restore($id);

            if (!$event) {
                return $this->errorResponse('Événement non trouvé', 404);
            }

            if ($event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            return $this->successResponse(
                $event,
                'Événement restauré avec succès'
            );
        } catch (\Exception $e) {
            Log::error('Erreur lors de la restauration de l\'événement', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse(
                'Erreur lors de la restauration de l\'événement',
                500
            );
        }
    }

    public function forceDelete(int $id)
    {
        try {
            $success = $this->eventRepository->forceDelete($id);

            if (!$success) {
                return $this->errorResponse('Événement non trouvé', 404);
            }

            return $this->successResponse(
                null,
                'Événement supprimé définitivement avec succès'
            );
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression définitive de l\'événement', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse(
                'Erreur lors de la suppression définitive de l\'événement',
                500
            );
        }
    }
}
