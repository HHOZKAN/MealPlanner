<?php

namespace App\Http\Controllers\Api\Ingredient;

use App\Http\Controllers\Controller;
use App\Contracts\Services\IngredientServiceInterface;
use App\DTOs\Ingredient\AssignmentData;
use App\DTOs\Ingredient\UpdateAssignmentData;
use App\Models\Event;
use App\Models\Ingredient;
use App\Models\IngredientAssignment;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

/**
 * Contrôleur spécialisé pour la gestion des assignations d'ingrédients
 * Responsabilités :
 * - Assigner des ingrédients aux participants
 * - Gérer les statuts d'achat (en attente, acheté)
 * - Traiter les reçus et preuves d'achat
 * - Lister les assignations
 */
class IngredientAssignmentController extends Controller
{
    use ApiResponse;

    public function __construct(
        private IngredientServiceInterface $ingredientService
    ) {}

    /**
     * Assigner un ingrédient à un utilisateur
     * 
     * Permet d'assigner une quantité spécifique d'un ingrédient à un participant.
     * L'utilisateur assigné sera responsable de l'achat de cette quantité.
     * 
     * @param Request $request
     * @param Event $event
     * @param Ingredient $ingredient
     * @return \Illuminate\Http\JsonResponse
     */
    public function assign(Request $request, Event $event, Ingredient $ingredient)
    {
        try {
            if (!$this->ingredientService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'user_id' => 'required|exists:users,id',
                'quantity' => 'required|numeric|min:0|max:' . $ingredient->quantity
            ]);

            $assignmentData = AssignmentData::fromRequest($validated);
            $assignment = $this->ingredientService->assignIngredient($event, $ingredient, $assignmentData);

            return $this->successResponse($assignment, 'Ingrédient assigné avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de l\'assignation de l\'ingrédient', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse(
                'Erreur lors de l\'assignation de l\'ingrédient: ' . $e->getMessage(), 
                500
            );
        }
    }

    /**
     * Liste des assignations d'un ingrédient
     * 
     * Retourne toutes les assignations pour un ingrédient donné,
     * incluant les informations sur les utilisateurs assignés.
     * 
     * @param Event $event
     * @param Ingredient $ingredient
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Event $event, Ingredient $ingredient)
    {
        try {
            if (!$this->ingredientService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $assignments = $this->ingredientService->getAssignments($event, $ingredient);

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
     * 
     * Permet de marquer un ingrédient comme acheté, d'ajouter le prix payé,
     * le nom du magasin et une photo du reçu.
     * 
     * @param Request $request
     * @param Event $event
     * @param Ingredient $ingredient
     * @param IngredientAssignment $assignment
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, Event $event, Ingredient $ingredient, IngredientAssignment $assignment)
    {
        try {
            if (!$this->ingredientService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'status' => 'required|in:pending,purchased',
                'price_paid' => 'required_if:status,purchased|nullable|numeric|min:0',
                'store_name' => 'nullable|string|max:255',
                'receipt_image' => 'nullable|string' // Base64 encoded image
            ]);

            $updateData = UpdateAssignmentData::fromRequest($validated);
            $updatedAssignment = $this->ingredientService->updateAssignment(
                $event, 
                $ingredient, 
                $assignment, 
                $updateData
            );

            return $this->successResponse($updatedAssignment, 'Assignation mise à jour avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la mise à jour de l\'assignation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse(
                'Erreur lors de la mise à jour de l\'assignation: ' . $e->getMessage(), 
                500
            );
        }
    }

    /**
     * Supprimer une assignation
     * 
     * Permet de retirer l'assignation d'un ingrédient à un utilisateur.
     * Seul l'organisateur ou l'utilisateur assigné peut effectuer cette action.
     * 
     * @param Event $event
     * @param Ingredient $ingredient
     * @param IngredientAssignment $assignment
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Event $event, Ingredient $ingredient, IngredientAssignment $assignment)
    {
        try {
            if (!$this->ingredientService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            // Vérifier que l'utilisateur peut supprimer cette assignation
            if ($assignment->user_id !== Auth::id() && !$this->ingredientService->canManageEvent($event, Auth::id())) {
                return $this->errorResponse('Vous ne pouvez supprimer que vos propres assignations', 403);
            }

            if ($assignment->ingredient_id !== $ingredient->id) {
                return $this->errorResponse('Assignation non trouvée pour cet ingrédient', 404);
            }

            $assignment->delete();

            // Si c'était la dernière assignation, remettre l'ingrédient en statut "needed"
            if ($ingredient->assignments()->count() === 0) {
                $ingredient->update(['status' => 'needed']);
            }

            Log::info('Assignation supprimée', [
                'ingredient_id' => $ingredient->id,
                'assignment_id' => $assignment->id,
                'deleted_by' => Auth::id()
            ]);

            return $this->successResponse(null, 'Assignation supprimée avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression de l\'assignation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse(
                'Erreur lors de la suppression de l\'assignation: ' . $e->getMessage(), 
                500
            );
        }
    }

    /**
     * Marquer une assignation comme achetée rapidement
     * 
     * Endpoint simplifié pour marquer rapidement un ingrédient comme acheté
     * sans avoir à fournir tous les détails.
     * 
     * @param Request $request
     * @param Event $event
     * @param Ingredient $ingredient
     * @param IngredientAssignment $assignment
     * @return \Illuminate\Http\JsonResponse
     */
    public function markAsPurchased(Request $request, Event $event, Ingredient $ingredient, IngredientAssignment $assignment)
    {
        try {
            if (!$this->ingredientService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'price_paid' => 'required|numeric|min:0'
            ]);

            $updateData = new UpdateAssignmentData(
                status: 'purchased',
                pricePaid: $validated['price_paid']
            );

            $updatedAssignment = $this->ingredientService->updateAssignment(
                $event, 
                $ingredient, 
                $assignment, 
                $updateData
            );

            return $this->successResponse($updatedAssignment, 'Ingrédient marqué comme acheté');
        } catch (\Exception $e) {
            Log::error('Erreur lors du marquage comme acheté', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse(
                'Erreur lors du marquage comme acheté: ' . $e->getMessage(), 
                500
            );
        }
    }
}
