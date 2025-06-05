<?php

namespace App\Http\Controllers\Api\Event;

use App\Http\Controllers\Controller;
use App\Contracts\Repositories\EventRepositoryInterface;
use App\DTOs\EventData;
use App\Models\Event;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class EventController extends Controller
{
    use ApiResponse;

    public function __construct(
        private EventRepositoryInterface $eventRepository
    ) {}

    public function index()
    {
        try {
            Log::info('Récupération des événements pour l\'utilisateur', ['user_id' => Auth::id()]);

            $events = $this->eventRepository->getEventsForUser(Auth::id());
            
            Log::info('Événements récupérés', ['count' => $events->count()]);

            return $this->successResponse($events, 'Événements récupérés avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des événements', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse(
                'Erreur lors de la récupération des événements',
                500
            );
        }
    }

    public function store(Request $request)
    {
        try {
            Log::info('Tentative de création d\'événement', $request->all());

            $eventData = EventData::fromRequest($request->all(), Auth::id());
            $validated = $request->validate($eventData->validate());

            $event = $this->eventRepository->create($eventData->toArray());

            // Ajouter automatiquement le créateur comme participant
            $event->participants()->create([
                'user_id' => Auth::id(),
                'status' => 'accepted'
            ]);

            Log::info('Événement créé avec organisateur ajouté comme participant', [
                'event_id' => $event->id,
                'organizer_id' => Auth::id()
            ]);

            return $this->successResponse($event, 'Événement créé avec succès', 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            Log::error('Erreur de validation', [
                'errors' => $e->errors(),
            ]);
            return $this->errorResponse($e->errors(), 422);
        } catch (\Exception $e) {
            Log::error('Erreur lors de la création de l\'événement', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse(
                'Erreur lors de la création de l\'événement: ' . $e->getMessage(),
                500
            );
        }
    }

    public function show(Event $event)
    {
        try {
            Log::info('Récupération d\'un événement', ['event_id' => $event->id]);

            if (!$this->eventRepository->canUserAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $event->load(['organizer', 'participants']);

            return $this->successResponse($event, 'Événement récupéré avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération de l\'événement', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse(
                'Erreur lors de la récupération de l\'événement',
                500
            );
        }
    }

    public function update(Request $request, Event $event)
    {
        try {
            Log::info('Tentative de mise à jour d\'événement', ['event_id' => $event->id]);

            if ($event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $eventData = EventData::fromRequest($request->all());
            $validated = $request->validate($eventData->validate());

            $event = $this->eventRepository->update($event, $eventData->toArray());

            Log::info('Événement mis à jour', ['event_id' => $event->id]);

            return $this->successResponse($event, 'Événement mis à jour avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la mise à jour de l\'événement', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse(
                'Erreur lors de la mise à jour de l\'événement',
                500
            );
        }
    }

    public function destroy(Event $event)
    {
        try {
            Log::info('Tentative de suppression d\'événement', ['event_id' => $event->id]);

            if ($event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $this->eventRepository->delete($event);

            Log::info('Événement supprimé', ['event_id' => $event->id]);

            return $this->successResponse(null, 'Événement supprimé avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression de l\'événement', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return $this->errorResponse(
                'Erreur lors de la suppression de l\'événement',
                500
            );
        }
    }
}
