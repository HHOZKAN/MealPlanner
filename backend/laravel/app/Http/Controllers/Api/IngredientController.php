<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Ingredient;
use App\Models\IngredientAssignment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Traits\ApiResponse;
use Illuminate\Support\Facades\Storage;

class IngredientController extends Controller
{
    use ApiResponse;

    /**
     * Liste des ingrédients d'un événement
     */
    public function index(Event $event)
    {
        try {
            if (!$this->canAccessEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $ingredients = $event->ingredients()
                ->with(['addedBy', 'assignments.user'])
                ->get()
                ->map(function ($ingredient) {
                    return $this->formatIngredient($ingredient);
                });

            return $this->successResponse($ingredients, 'Ingrédients récupérés avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des ingrédients', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la récupération des ingrédients', 500);
        }
    }

    /**
     * Créer un nouvel ingrédient
     */
    public function store(Request $request, Event $event)
    {
        try {
            if (!$this->canAccessEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'quantity' => 'required|numeric|min:0',
                'unit' => 'required|string|in:' . implode(',', array_keys(Ingredient::UNITS)),
                'estimated_price' => 'nullable|numeric|min:0',
                'notes' => 'nullable|string'
            ]);

            // Créer l'ingrédient avec des valeurs explicites
            $ingredient = new Ingredient();
            $ingredient->event_id = $event->id;
            $ingredient->name = $validated['name'];
            $ingredient->quantity = $validated['quantity'];
            $ingredient->unit = $validated['unit'];
            $ingredient->estimated_price = $validated['estimated_price'];
            $ingredient->notes = $validated['notes'];
            $ingredient->added_by = Auth::id();
            $ingredient->status = Ingredient::STATUS_NEEDED;
            $ingredient->save();

            Log::info('Ingrédient créé', [
                'ingredient_id' => $ingredient->id,
                'event_id' => $event->id
            ]);

            return $this->successResponse(
                $this->formatIngredient($ingredient->load(['addedBy'])),
                'Ingrédient ajouté avec succès',
                201
            );
        } catch (\Exception $e) {
            Log::error('Erreur lors de la création de l\'ingrédient', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la création de l\'ingrédient: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Afficher un ingrédient spécifique
     */
    public function show(Event $event, Ingredient $ingredient)
    {
        try {
            if (!$this->canAccessEvent($event) || $ingredient->event_id !== $event->id) {
                return $this->errorResponse('Non autorisé', 403);
            }

            return $this->successResponse(
                $this->formatIngredient($ingredient->load(['addedBy', 'assignments.user'])),
                'Ingrédient récupéré avec succès'
            );
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération de l\'ingrédient', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la récupération de l\'ingrédient', 500);
        }
    }

    /**
     * Mettre à jour un ingrédient
     */
    public function update(Request $request, Event $event, Ingredient $ingredient)
    {
        try {
            if (!$this->canManageEvent($event) || $ingredient->event_id !== $event->id) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'name' => 'sometimes|required|string|max:255',
                'quantity' => 'sometimes|required|numeric|min:0',
                'unit' => 'sometimes|required|string|in:' . implode(',', array_keys(Ingredient::UNITS)),
                'estimated_price' => 'nullable|numeric|min:0',
                'actual_price' => 'nullable|numeric|min:0',
                'status' => 'sometimes|required|in:' . implode(',', [
                    Ingredient::STATUS_NEEDED,
                    Ingredient::STATUS_ASSIGNED,
                    Ingredient::STATUS_PURCHASED
                ]),
                'notes' => 'nullable|string'
            ]);

            $ingredient->update($validated);

            Log::info('Ingrédient mis à jour', [
                'ingredient_id' => $ingredient->id,
                'event_id' => $event->id
            ]);

            return $this->successResponse(
                $this->formatIngredient($ingredient->load(['addedBy', 'assignments.user'])),
                'Ingrédient mis à jour avec succès'
            );
        } catch (\Exception $e) {
            Log::error('Erreur lors de la mise à jour de l\'ingrédient', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la mise à jour de l\'ingrédient', 500);
        }
    }

    /**
     * Supprimer un ingrédient
     */
    public function destroy(Event $event, Ingredient $ingredient)
    {
        try {
            if (!$this->canManageEvent($event) || $ingredient->event_id !== $event->id) {
                return $this->errorResponse('Non autorisé', 403);
            }

            // Supprimer les assignments associés
            $ingredient->assignments()->delete();

            // Soft delete de l'ingrédient
            $ingredient->delete();

            Log::info('Ingrédient supprimé', [
                'ingredient_id' => $ingredient->id,
                'event_id' => $event->id
            ]);

            return $this->successResponse(null, 'Ingrédient supprimé avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression de l\'ingrédient', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la suppression de l\'ingrédient', 500);
        }
    }

    /**
     * Assigner un ingrédient à un utilisateur
     */
    public function assign(Request $request, Event $event, Ingredient $ingredient)
    {
        try {
            if (!$this->canAccessEvent($event) || $ingredient->event_id !== $event->id) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'user_id' => 'required|exists:users,id',
                'quantity' => 'required|numeric|min:0|max:' . $ingredient->quantity
            ]);

            // Vérifier si l'utilisateur est participant à l'événement ou organisateur
            if (!$event->participants()->where('user_id', $validated['user_id'])->exists() && 
                $event->organizer_id !== $validated['user_id']) {
                return $this->errorResponse('L\'utilisateur doit être participant à l\'événement', 422);
            }

            $assignment = $ingredient->assignments()->create([
                'user_id' => $validated['user_id'],
                'quantity' => $validated['quantity'],
                'status' => IngredientAssignment::STATUS_PENDING
            ]);

            // Mettre à jour le statut de l'ingrédient
            $ingredient->update(['status' => Ingredient::STATUS_ASSIGNED]);

            Log::info('Ingrédient assigné', [
                'ingredient_id' => $ingredient->id,
                'user_id' => $validated['user_id']
            ]);

            return $this->successResponse(
                $assignment->load(['user']),
                'Ingrédient assigné avec succès'
            );
        } catch (\Exception $e) {
            Log::error('Erreur lors de l\'assignation de l\'ingrédient', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de l\'assignation de l\'ingrédient', 500);
        }
    }

    /**
     * Formater un ingrédient pour la réponse API
     */
    private function formatIngredient($ingredient)
    {
        return [
            'id' => $ingredient->id,
            'name' => $ingredient->name,
            'quantity' => $ingredient->quantity,
            'unit' => $ingredient->unit,
            'unit_label' => Ingredient::UNITS[$ingredient->unit],
            'estimated_price' => $ingredient->estimated_price,
            'actual_price' => $ingredient->actual_price,
            'status' => $ingredient->status,
            'notes' => $ingredient->notes,
            'emoji' => $ingredient->emoji ?? '🛒',
            'added_by' => $ingredient->addedBy,
            'assignments' => $ingredient->assignments,
            'created_at' => $ingredient->created_at,
            'updated_at' => $ingredient->updated_at
        ];
    }

    /**
     * Liste des assignations d'un ingrédient
     */
    public function assignments(Event $event, Ingredient $ingredient)
    {
        try {
            if (!$this->canAccessEvent($event) || $ingredient->event_id !== $event->id) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $assignments = $ingredient->assignments()
                ->with('user')
                ->get();

            return $this->successResponse($assignments, 'Assignations récupérées avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des assignations', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la récupération des assignations', 500);
        }
    }

    /**
     * Mettre à jour une assignation
     */
    public function updateAssignment(Request $request, Event $event, Ingredient $ingredient, IngredientAssignment $assignment)
    {
        try {
            // Vérifie si l'utilisateur est participant à l'événement
            if (!$this->canAccessEvent($event) || $ingredient->event_id !== $event->id) {
                return $this->errorResponse('Non autorisé', 403);
            }
    
            // Supprimons cette vérification restrictive
            // if ($assignment->user_id !== Auth::id()) {
            //     return $this->errorResponse('Vous ne pouvez modifier que vos propres assignations', 403);
            // }
    
            $validated = $request->validate([
                'status' => 'required|in:pending,purchased',
                'price_paid' => 'required_if:status,purchased|nullable|numeric|min:0',
                'store_name' => 'nullable|string|max:255',
                'receipt_image' => 'nullable|string' // Base64 encoded image
            ]);
    
            // Gérer l'upload de l'image si présente
            if (isset($validated['receipt_image'])) {
                $imageName = 'receipt_' . time() . '.jpg';
                Storage::disk('public')->put(
                    'receipts/' . $imageName,
                    base64_decode(explode(',', $validated['receipt_image'])[1])
                );
                $validated['receipt_image'] = 'receipts/' . $imageName;
            }
    
            $assignment->update($validated);
    
            // Si marqué comme acheté, mettre à jour le prix réel de l'ingrédient
            if ($validated['status'] === 'purchased' && isset($validated['price_paid'])) {
                $ingredient->update([
                    'actual_price' => $validated['price_paid'],
                    'status' => 'purchased'
                ]);
            }
    
            Log::info('Assignation mise à jour', [
                'ingredient_id' => $ingredient->id,
                'assignment_id' => $assignment->id,
                'updated_by' => Auth::id()
            ]);
    
            return $this->successResponse(
                $assignment->load('user'),
                'Assignation mise à jour avec succès'
            );
        } catch (\Exception $e) {
            Log::error('Erreur lors de la mise à jour de l\'assignation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la mise à jour de l\'assignation', 500);
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
     * Vérifier si l'utilisateur peut gérer l'événement
     */
    private function canManageEvent(Event $event)
    {
        return $event->organizer_id === Auth::id();
    }
}
