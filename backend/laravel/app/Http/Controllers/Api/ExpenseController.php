<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Expense;
use App\Models\ExpenseShare;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Traits\ApiResponse;

class ExpenseController extends Controller
{
    use ApiResponse;

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
        return $event->organizer_id === Auth::id() || 
               $event->participants()->where('user_id', Auth::id())->exists();
    }

    /**
     * Calculer et créer les dépenses pour un événement
     */
    public function calculateExpenses(Event $event)
    {
        try {
            if (!$this->canManageEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            // Récupérer tous les ingrédients achetés
            $purchasedIngredients = $event->ingredients()
                ->whereHas('assignments', function ($query) {
                    $query->where('status', 'purchased');
                })
                ->with(['assignments' => function ($query) {
                    $query->where('status', 'purchased')
                        ->with('user');
                }])
                ->get();

            // Calculer les dépenses par personne
            $expenses = [];
            $participants = $event->participants()->get();
            $participantCount = $participants->count();

            foreach ($purchasedIngredients as $ingredient) {
                foreach ($ingredient->assignments as $assignment) {
                    if ($assignment->price_paid) {
                        $shareAmount = $assignment->price_paid / $participantCount;

                        $expense = Expense::create([
                            'event_id' => $event->id,
                            'paid_by' => $assignment->user_id,
                            'amount' => $assignment->price_paid,
                            'description' => "Achat de {$ingredient->name}",
                            'receipt_image' => $assignment->receipt_image
                        ]);

                        // Créer les parts pour chaque participant
                        foreach ($participants as $participant) {
                            ExpenseShare::create([
                                'expense_id' => $expense->id,
                                'user_id' => $participant->user_id,
                                'amount' => $shareAmount,
                                'status' => $participant->user_id === $assignment->user_id ? 'paid' : 'pending'
                            ]);
                        }

                        $expenses[] = $expense;
                    }
                }
            }

            return $this->successResponse([
                'expenses' => $expenses,
                'total_amount' => collect($expenses)->sum('amount'),
                'per_person' => collect($expenses)->sum('amount') / $participantCount
            ], 'Dépenses calculées avec succès');

        } catch (\Exception $e) {
            Log::error('Erreur lors du calcul des dépenses', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du calcul des dépenses', 500);
        }
    }

    /**
     * Voir le résumé des dépenses
     */
    public function summary(Event $event)
    {
        try {
            if (!$this->canAccessEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $summary = [
                'total_expenses' => $event->expenses()->sum('amount'),
                'expenses_by_user' => $event->expenses()
                    ->with('paidBy')
                    ->get()
                    ->groupBy('paid_by')
                    ->map(function ($expenses) {
                        return [
                            'total_paid' => $expenses->sum('amount'),
                            'expenses' => $expenses
                        ];
                    }),
                'shares_to_pay' => ExpenseShare::whereHas('expense', function ($query) use ($event) {
                    $query->where('event_id', $event->id);
                })
                ->where('status', 'pending')
                ->where('user_id', Auth::id())
                ->with('expense.paidBy')
                ->get()
            ];

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
     * Marquer une part de dépense comme payée
     */
    public function markAsPaid(Event $event, ExpenseShare $share)
    {
        try {
            if (!$this->canAccessEvent($event) || $share->user_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $share->update([
                'status' => 'paid',
                'paid_at' => now()
            ]);

            return $this->successResponse($share, 'Part marquée comme payée');

        } catch (\Exception $e) {
            Log::error('Erreur lors du marquage du paiement', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du marquage du paiement', 500);
        }
    }

    
}