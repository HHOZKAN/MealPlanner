<?php

namespace App\Http\Controllers\Api\Ingredient;

use App\Http\Controllers\Controller;
use App\Contracts\Services\IngredientServiceInterface;
use App\DTOs\Ingredient\IngredientData;
use App\Models\Event;
use App\Models\Ingredient;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class IngredientController extends Controller
{
    use ApiResponse;

    public function __construct(
        private IngredientServiceInterface $ingredientService
    ) {}

    /**
     * Liste des ingrédients d'un événement
     * 
     * @param Event $event
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Event $event)
    {
        try {
            if (!$this->ingredientService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $ingredients = $this->ingredientService->listIngredients($event);

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
     * 
     * @param Request $request
     * @param Event $event
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request, Event $event)
    {
        try {
            if (!$this->ingredientService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'quantity' => 'required|numeric|min:0',
                'unit' => 'required|string|in:' . implode(',', array_keys(\App\ValueObjects\IngredientUnit::getUnits())),
                'estimated_price' => 'nullable|numeric|min:0',
                'notes' => 'nullable|string',
                'emoji' => 'nullable|string'
            ]);

            $ingredientData = IngredientData::fromRequest($validated);
            $ingredient = $this->ingredientService->createIngredient($event, $ingredientData, Auth::id());

            return $this->successResponse($ingredient, 'Ingrédient ajouté avec succès', 201);
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
     * 
     * @param Event $event
     * @param Ingredient $ingredient
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Event $event, Ingredient $ingredient)
    {
        try {
            if (!$this->ingredientService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $ingredient = $this->ingredientService->getIngredient($event, $ingredient);

            return $this->successResponse($ingredient, 'Ingrédient récupéré avec succès');
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
     * 
     * @param Request $request
     * @param Event $event
     * @param Ingredient $ingredient
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, Event $event, Ingredient $ingredient)
    {
        try {
            if (!$this->ingredientService->canManageEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'name' => 'sometimes|required|string|max:255',
                'quantity' => 'sometimes|required|numeric|min:0',
                'unit' => 'sometimes|required|string|in:' . implode(',', array_keys(\App\ValueObjects\IngredientUnit::getUnits())),
                'estimated_price' => 'nullable|numeric|min:0',
                'actual_price' => 'nullable|numeric|min:0',
                'status' => 'sometimes|required|string|in:' . implode(',', \App\ValueObjects\IngredientStatus::getValidStatuses()),
                'notes' => 'nullable|string',
                'emoji' => 'nullable|string'
            ]);

            $ingredientData = IngredientData::fromRequest($validated);
            $updatedIngredient = $this->ingredientService->updateIngredient($event, $ingredient, $ingredientData);

            return $this->successResponse($updatedIngredient, 'Ingrédient mis à jour avec succès');
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
     * 
     * @param Event $event
     * @param Ingredient $ingredient
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Event $event, Ingredient $ingredient)
    {
        try {
            if (!$this->ingredientService->canManageEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $this->ingredientService->deleteIngredient($event, $ingredient);

            return $this->successResponse(null, 'Ingrédient supprimé avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression de l\'ingrédient', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la suppression de l\'ingrédient', 500);
        }
    }
}
