<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Expense;
use App\Models\ExpenseShare;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
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
     * Get all expenses for an event
     */
    public function index(Event $event)
    {
        try {
            if (!$this->canAccessEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $expenses = $event->expenses()
                ->with(['paidBy', 'ingredient', 'shares.user'])
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($expense) {
                    return [
                        'id' => $expense->id,
                        'event_id' => $expense->event_id,
                        'ingredient_id' => $expense->ingredient_id,
                        'ingredient_name' => $expense->ingredientName,
                        'payer_id' => $expense->payer_id,
                        'payer_name' => $expense->payerName,
                        'amount' => $expense->amount,
                        'shares' => $expense->sharesFormatted,
                        'created_at' => $expense->created_at,
                        'category' => $expense->category,
                    ];
                });

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
     * Create a new expense
     */
    public function store(Request $request, Event $event)
    {
        try {
            if (!$this->canManageEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'ingredient_id' => 'required|exists:ingredients,id',
                'payer_id' => 'required|exists:users,id',
                'amount' => 'required|numeric|min:0',
                'shares' => 'required|array'
            ]);

            DB::beginTransaction();

            $expense = Expense::create([
                'event_id' => $event->id,
                'ingredient_id' => $validated['ingredient_id'],
                'payer_id' => $validated['payer_id'],
                'amount' => $validated['amount']
            ]);

            // Create expense shares
            foreach ($validated['shares'] as $userId => $amount) {
                ExpenseShare::create([
                    'expense_id' => $expense->id,
                    'user_id' => $userId,
                    'amount' => $amount,
                    'status' => $userId == $validated['payer_id'] ? 'paid' : 'pending'
                ]);
            }

            DB::commit();

            $expense->load(['paidBy', 'ingredient', 'shares.user']);

            return $this->successResponse([
                'id' => $expense->id,
                'event_id' => $expense->event_id,
                'ingredient_id' => $expense->ingredient_id,
                'ingredient_name' => $expense->ingredientName,
                'payer_id' => $expense->payer_id,
                'payer_name' => $expense->payerName,
                'amount' => $expense->amount,
                'shares' => $expense->sharesFormatted,
                'created_at' => $expense->created_at,
                'category' => $expense->category,
            ], 'Dépense créée avec succès');

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Erreur lors de la création de la dépense', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la création de la dépense: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Update an existing expense
     */
    public function update(Request $request, Event $event, Expense $expense)
    {
        try {
            if (!$this->canManageEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            // Vérifier que la dépense appartient à l'événement
            if ($expense->event_id !== $event->id) {
                return $this->errorResponse('Dépense non trouvée pour cet événement', 404);
            }

            $validated = $request->validate([
                'ingredient_id' => 'required|exists:ingredients,id',
                'payer_id' => 'required|exists:users,id',
                'amount' => 'required|numeric|min:0',
                'shares' => 'required|array'
            ]);

            DB::beginTransaction();

            // Mettre à jour la dépense
            $expense->update([
                'ingredient_id' => $validated['ingredient_id'],
                'payer_id' => $validated['payer_id'],
                'amount' => $validated['amount']
            ]);

            // Supprimer les anciennes parts
            $expense->shares()->delete();

            // Créer les nouvelles parts
            foreach ($validated['shares'] as $userId => $amount) {
                ExpenseShare::create([
                    'expense_id' => $expense->id,
                    'user_id' => $userId,
                    'amount' => $amount,
                    'status' => $userId == $validated['payer_id'] ? 'paid' : 'pending'
                ]);
            }

            DB::commit();

            $expense->load(['paidBy', 'ingredient', 'shares.user']);

            return $this->successResponse([
                'id' => $expense->id,
                'event_id' => $expense->event_id,
                'ingredient_id' => $expense->ingredient_id,
                'ingredient_name' => $expense->ingredientName,
                'payer_id' => $expense->payer_id,
                'payer_name' => $expense->payerName,
                'amount' => $expense->amount,
                'shares' => $expense->sharesFormatted,
                'created_at' => $expense->created_at,
            ], 'Dépense mise à jour avec succès');

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Erreur lors de la mise à jour de la dépense', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la mise à jour de la dépense: ' . $e->getMessage(), 500);
        }
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
            $participantCount = $participants->count() + 1; // +1 pour inclure l'organisateur

            foreach ($purchasedIngredients as $ingredient) {
                foreach ($ingredient->assignments as $assignment) {
                    if ($assignment->price_paid) {
                        $shareAmount = $assignment->price_paid / $participantCount;

                        $expense = Expense::create([
                            'event_id' => $event->id,
                            'ingredient_id' => $ingredient->id,
                            'payer_id' => $assignment->user_id,
                            'amount' => $assignment->price_paid,
                            'description' => "Achat de {$ingredient->name}",
                            'receipt_image' => $assignment->receipt_image
                        ]);

                        // Créer les parts pour l'organisateur
                        ExpenseShare::create([
                            'expense_id' => $expense->id,
                            'user_id' => $event->organizer_id,
                            'amount' => $shareAmount,
                            'status' => $event->organizer_id === $assignment->user_id ? 'paid' : 'pending'
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
                    ->with(['paidBy', 'ingredient', 'shares'])
                    ->get()
                    ->groupBy('payer_id')
                    ->map(function ($expenses) {
                        return [
                            'total_paid' => $expenses->sum('amount'),
                            'expenses' => $expenses->map(function ($expense) {
                                return [
                                    'id' => $expense->id,
                                    'ingredient_id' => $expense->ingredient_id,
                                    'ingredient_name' => $expense->ingredientName,
                                    'amount' => $expense->amount,
                                    'created_at' => $expense->created_at,
                                    'shares' => $expense->sharesFormatted
                                ];
                            })
                        ];
                    }),
                'shares_to_pay' => ExpenseShare::whereHas('expense', function ($query) use ($event) {
                    $query->where('event_id', $event->id);
                })
                ->where('status', 'pending')
                ->where('user_id', Auth::id())
                ->with(['expense.paidBy', 'expense.ingredient'])
                ->get()
                ->map(function ($share) {
                    return [
                        'id' => $share->id,
                        'amount' => $share->amount,
                        'expense' => [
                            'id' => $share->expense->id,
                            'ingredient_name' => $share->expense->ingredientName,
                            'payer_name' => $share->expense->payerName,
                            'amount' => $share->expense->amount,
                            'created_at' => $share->expense->created_at
                        ]
                    ];
                })
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

    /**
     * Calculer les soldes optimisés pour un événement
     */
    public function balances(Event $event)
    {
        try {
            if (!$this->canAccessEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            // Récupérer toutes les dépenses avec leurs parts
            $expenses = $event->expenses()->with(['paidBy', 'shares.user'])->get();
            
            if ($expenses->isEmpty()) {
                return $this->successResponse([
                    'balances' => [],
                    'reimbursements' => [],
                    'total_expenses' => 0
                ], 'Aucune dépense trouvée');
            }

            // Étape 1: Calculer les soldes individuels
            $balances = [];
            $userNames = [];

            foreach ($expenses as $expense) {
                $payerId = $expense->payer_id;
                $payerName = $expense->paidBy->name;
                
                // Initialiser le solde du payeur s'il n'existe pas
                if (!isset($balances[$payerId])) {
                    $balances[$payerId] = 0;
                    $userNames[$payerId] = $payerName;
                }
                
                // Le payeur a avancé l'argent
                $balances[$payerId] += $expense->amount;
                
                // Soustraire les parts de chaque participant
                foreach ($expense->shares as $share) {
                    $userId = $share->user_id;
                    $userName = $share->user->name;
                    
                    if (!isset($balances[$userId])) {
                        $balances[$userId] = 0;
                        $userNames[$userId] = $userName;
                    }
                    
                    $balances[$userId] -= $share->amount;
                }
            }

            // Filtrer les soldes proches de zéro (moins de 0.01€)
            $filteredBalances = array_filter($balances, function($balance) {
                return abs($balance) >= 0.01;
            });

            // Étape 2: Calculer les transactions optimisées
            $transactions = $this->calculateOptimalTransactions($filteredBalances, $userNames);

            // Préparer la réponse
            $balancesList = [];
            foreach ($filteredBalances as $userId => $balance) {
                $balancesList[] = [
                    'user_id' => $userId,
                    'user_name' => $userNames[$userId],
                    'balance' => round($balance, 2)
                ];
            }

            // Trier par solde décroissant
            usort($balancesList, function($a, $b) {
                return $b['balance'] <=> $a['balance'];
            });

            return $this->successResponse([
                'balances' => $balancesList,
                'reimbursements' => $transactions,
                'total_expenses' => $expenses->sum('amount')
            ], 'Soldes calculés avec succès');

        } catch (\Exception $e) {
            Log::error('Erreur lors du calcul des soldes', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du calcul des soldes', 500);
        }
    }

    /**
     * Calculer les transactions optimales pour équilibrer les soldes
     */
    private function calculateOptimalTransactions($balances, $userNames)
    {
        $transactions = [];
        
        // Séparer créanciers et débiteurs
        $creditors = []; // Solde positif - on leur doit de l'argent
        $debtors = [];   // Solde négatif - ils doivent de l'argent
        
        foreach ($balances as $userId => $balance) {
            if ($balance > 0.01) {
                $creditors[] = ['user_id' => $userId, 'amount' => $balance];
            } elseif ($balance < -0.01) {
                $debtors[] = ['user_id' => $userId, 'amount' => abs($balance)];
            }
        }
        
        // Trier par montant décroissant
        usort($creditors, function($a, $b) { return $b['amount'] <=> $a['amount']; });
        usort($debtors, function($a, $b) { return $b['amount'] <=> $a['amount']; });
        
        // Algorithme de simplification des dettes
        $i = 0; // Index pour les créanciers
        $j = 0; // Index pour les débiteurs
        
        while ($i < count($creditors) && $j < count($debtors)) {
            $creditor = &$creditors[$i];
            $debtor = &$debtors[$j];
            
            // Montant de la transaction
            $transactionAmount = min($creditor['amount'], $debtor['amount']);
            
            if ($transactionAmount >= 0.01) {
                $transactions[] = [
                    'from_user_id' => $debtor['user_id'],
                    'from_user_name' => $userNames[$debtor['user_id']],
                    'to_user_id' => $creditor['user_id'],
                    'to_user_name' => $userNames[$creditor['user_id']],
                    'amount' => round($transactionAmount, 2)
                ];
                
                // Mettre à jour les montants
                $creditor['amount'] -= $transactionAmount;
                $debtor['amount'] -= $transactionAmount;
            }
            
            // Passer au suivant si le montant est épuisé
            if ($creditor['amount'] < 0.01) {
                $i++;
            }
            if ($debtor['amount'] < 0.01) {
                $j++;
            }
        }
        
        return $transactions;
    }
}
