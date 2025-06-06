<?php

namespace App\Http\Controllers\Api\Expense;

use App\Http\Controllers\Controller;
use App\Contracts\Services\ExpenseServiceInterface;
use App\DTOs\Expense\ExpenseData;
use App\Models\Event;
use App\Models\Expense;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

/**
 * Contrôleur pour la gestion des dépenses
 * Responsabilités :
 * - CRUD des dépenses
 * - Calcul automatique des dépenses basées sur les achats
 * - Génération de résumés
 */
class ExpenseController extends Controller
{
    use ApiResponse;

    public function __construct(
        private ExpenseServiceInterface $expenseService
    ) {}

    /**
     * Liste des dépenses d'un événement
     * 
     * @param Event $event
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Event $event)
    {
        try {
            if (!$this->expenseService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $expenses = $this->expenseService->listExpenses($event);

            return $this->successResponse($expenses, 'Dépenses récupérées avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des dépenses', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la récupération des dépenses', 500);
        }
    }

    /**
     * Créer une nouvelle dépense
     * 
     * @param Request $request
     * @param Event $event
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request, Event $event)
    {
        try {
            if (!$this->expenseService->canManageEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'ingredient_id' => 'required|exists:ingredients,id',
                'payer_id' => 'required|exists:users,id',
                'amount' => 'required|numeric|min:0',
                'description' => 'nullable|string|max:255',
                'category' => 'nullable|string|in:' . implode(',', \App\ValueObjects\ExpenseCategory::getValidCategories()),
                'receipt_image' => 'nullable|string',
                'shares' => 'required|array|min:1',
                'shares.*' => 'required|numeric|min:0'
            ]);

            $expenseData = ExpenseData::fromRequest($validated);
            $expense = $this->expenseService->createExpense($event, $expenseData, $validated['shares']);

            return $this->successResponse($expense, 'Dépense créée avec succès', 201);
        } catch (\Exception $e) {
            Log::error('Erreur lors de la création de la dépense', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la création de la dépense: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Afficher une dépense spécifique
     * 
     * @param Event $event
     * @param Expense $expense
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Event $event, Expense $expense)
    {
        try {
            if (!$this->expenseService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            if ($expense->event_id !== $event->id) {
                return $this->errorResponse('Dépense non trouvée pour cet événement', 404);
            }

            $formattedExpense = $this->expenseService->formatExpense($expense->load(['paidBy', 'ingredient', 'shares.user']));

            return $this->successResponse($formattedExpense, 'Dépense récupérée avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération de la dépense', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la récupération de la dépense', 500);
        }
    }

    /**
     * Mettre à jour une dépense
     * 
     * @param Request $request
     * @param Event $event
     * @param Expense $expense
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, Event $event, Expense $expense)
    {
        try {
            if (!$this->expenseService->canManageEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'ingredient_id' => 'sometimes|required|exists:ingredients,id',
                'payer_id' => 'sometimes|required|exists:users,id',
                'amount' => 'sometimes|required|numeric|min:0',
                'description' => 'nullable|string|max:255',
                'category' => 'nullable|string|in:' . implode(',', \App\ValueObjects\ExpenseCategory::getValidCategories()),
                'receipt_image' => 'nullable|string',
                'shares' => 'sometimes|required|array|min:1',
                'shares.*' => 'required|numeric|min:0'
            ]);

            $expenseData = ExpenseData::fromRequest($validated);
            $updatedExpense = $this->expenseService->updateExpense($event, $expense, $expenseData, $validated['shares'] ?? []);

            return $this->successResponse($updatedExpense, 'Dépense mise à jour avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la mise à jour de la dépense', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la mise à jour de la dépense: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Supprimer une dépense
     * 
     * @param Event $event
     * @param Expense $expense
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Event $event, Expense $expense)
    {
        try {
            if (!$this->expenseService->canManageEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            if ($expense->event_id !== $event->id) {
                return $this->errorResponse('Dépense non trouvée pour cet événement', 404);
            }

            // Supprimer les parts associées
            $expense->shares()->delete();
            
            // Supprimer la dépense
            $expense->delete();

            Log::info('Dépense supprimée', [
                'expense_id' => $expense->id,
                'event_id' => $event->id,
                'deleted_by' => Auth::id()
            ]);

            return $this->successResponse(null, 'Dépense supprimée avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression de la dépense', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la suppression de la dépense: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Calculer automatiquement les dépenses basées sur les achats
     * 
     * @param Event $event
     * @return \Illuminate\Http\JsonResponse
     */
    public function calculateExpenses(Event $event)
    {
        try {
            if (!$this->expenseService->canManageEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $result = $this->expenseService->calculateExpenses($event);

            return $this->successResponse($result, 'Dépenses calculées avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors du calcul des dépenses', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du calcul des dépenses: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Résumé des dépenses pour un événement
     * 
     * @param Event $event
     * @return \Illuminate\Http\JsonResponse
     */
    public function summary(Event $event)
    {
        try {
            if (!$this->expenseService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $summary = $this->expenseService->getExpensesSummary($event, Auth::id());

            return $this->successResponse($summary, 'Résumé des dépenses récupéré avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération du résumé', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la récupération du résumé', 500);
        }
    }

    /**
     * Calculer les soldes et remboursements optimisés
     * 
     * @param Event $event
     * @return \Illuminate\Http\JsonResponse
     */
    public function balances(Event $event)
    {
        try {
            if (!$this->expenseService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $balances = $this->expenseService->calculateBalances($event);

            return $this->successResponse($balances, 'Soldes calculés avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors du calcul des soldes', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du calcul des soldes', 500);
        }
    }
}
