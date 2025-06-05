<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\PendingInvitation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Traits\ApiResponse;

class EventController extends Controller
{
    use ApiResponse;

    public function index()
    {
        try {
            Log::info('Récupération des événements pour l\'utilisateur', ['user_id' => Auth::id()]);

            $events = Event::with(['organizer'])
                ->where('organizer_id', Auth::id())
                ->orWhereHas('participants', function ($query) {
                    $query->where('user_id', Auth::id());
                })
                ->latest()
                ->get();

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

            $validated = $request->validate([
                'title' => 'required|string|max:255',
                'description' => 'nullable|string',
                'date' => 'required|date|after:now',
                'location' => 'nullable|string|max:255',
                'type' => 'required|string|in:dinner,lunch,brunch,breakfast,other',
            ]);

            Log::info('Données validées', $validated);

            $event = Event::create([
                ...$validated,
                'organizer_id' => Auth::id(),
                'status' => 'draft'
            ]);

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

            if (!$this->canAccessEvent($event)) {
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

            $validated = $request->validate([
                'title' => 'sometimes|required|string|max:255',
                'description' => 'nullable|string',
                'date' => 'sometimes|required|date|after:now',
                'location' => 'nullable|string|max:255',
                'type' => 'sometimes|required|string|in:dinner,lunch,brunch,breakfast,other',
                'status' => 'sometimes|required|in:draft,planning,confirmed,cancelled,completed',
            ]);

            $event->update($validated);

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

            $event->delete();

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

    private function canAccessEvent(Event $event)
    {
        return $event->organizer_id === Auth::id() ||
            $event->participants()->where('user_id', Auth::id())->exists();
    }

    public function trashed()
    {
        try {
            $events = Event::onlyTrashed()
                ->where('organizer_id', Auth::id())
                ->latest()
                ->get();

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

    public function restore($id)
    {
        try {
            $event = Event::onlyTrashed()
                ->where('id', $id)
                ->firstOrFail();

            if ($event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $event->restore();

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

    public function forceDelete($id)
    {
        try {
            $event = Event::withTrashed()
                ->where('id', $id)
                ->firstOrFail();

            if ($event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $event->forceDelete();

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
