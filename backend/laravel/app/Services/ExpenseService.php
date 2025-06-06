<?php

namespace App\Services;

use App\Contracts\Services\ExpenseServiceInterface;
use App\DTOs\Expense\ExpenseData;
use App\Models\Event;
use App\Models\Expense;
use App\Models\ExpenseShare;
use App\ValueObjects\ExpenseStatus;
use App\ValueObjects\ExpenseCategory;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ExpenseService implements ExpenseServiceInterface
{
    /**
     * {@inheritdoc}
     */
    public function listExpenses(Event $event): Collection
    {
        return $event->expenses()
            ->with(['paidBy', 'ingredient', 'shares.user'])
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(fn($expense) => $this->formatExpense($expense));
    }

    /**
     * {@inheritdoc}
     */
    public function createExpense(Event $event, ExpenseData $data, array $shares): array
    {
        DB::beginTransaction();

        try {
            $expense = new Expense();
            $expense->event_id = $event->id;
            $expense->ingredient_id = $data->ingredientId;
            $expense->payer_id = $data->payerId;
            $expense->amount = $data->amount;
            $expense->description = $data->description;
            $expense->category = $data->category ?? ExpenseCategory::INGREDIENT->value;
            $expense->receipt_image = $data->receiptImage;
            $expense->save();

            // Créer les parts de dépense
            foreach ($shares as $userId => $amount) {
                $share = new ExpenseShare();
                $share->expense_id = $expense->id;
                $share->user_id = $userId;
                $share->amount = $amount;
                $share->status = $userId == $data->payerId ? ExpenseStatus::PAID->value : ExpenseStatus::PENDING->value;
                $share->save();
            }

            DB::commit();

            Log::info('Dépense créée', [
                'expense_id' => $expense->id,
                'event_id' => $event->id,
                'amount' => $data->amount,
                'payer_id' => $data->payerId
            ]);

            return $this->formatExpense($expense->load(['paidBy', 'ingredient', 'shares.user']));
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * {@inheritdoc}
     */
    public function updateExpense(Event $event, Expense $expense, ExpenseData $data, array $shares): array
    {
        if ($expense->event_id !== $event->id) {
            throw new \Exception('Dépense non trouvée pour cet événement');
        }

        DB::beginTransaction();

        try {
            // Mettre à jour la dépense
            $expense->ingredient_id = $data->ingredientId;
            $expense->payer_id = $data->payerId;
            $expense->amount = $data->amount;
            $expense->description = $data->description;
            $expense->category = $data->category ?? $expense->category;
            $expense->receipt_image = $data->receiptImage ?? $expense->receipt_image;
            $expense->save();

            // Supprimer les anciennes parts
            $expense->shares()->delete();

            // Créer les nouvelles parts
            foreach ($shares as $userId => $amount) {
                $share = new ExpenseShare();
                $share->expense_id = $expense->id;
                $share->user_id = $userId;
                $share->amount = $amount;
                $share->status = $userId == $data->payerId ? ExpenseStatus::PAID->value : ExpenseStatus::PENDING->value;
                $share->save();
            }

            DB::commit();

            Log::info('Dépense mise à jour', [
                'expense_id' => $expense->id,
                'event_id' => $event->id,
                'amount' => $data->amount
            ]);

            return $this->formatExpense($expense->load(['paidBy', 'ingredient', 'shares.user']));
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * {@inheritdoc}
     */
    public function calculateExpenses(Event $event): array
    {
        // Récupérer tous les ingrédients achetés
        $purchasedIngredients = $event->ingredients()
            ->whereHas('assignments', function ($query) {
                $query->where('status', 'purchased');
            })
            ->with(['assignments' => function ($query) {
                $query->where('status', 'purchased')->with('user');
            }])
            ->get();

        if ($purchasedIngredients->isEmpty()) {
            return [
                'expenses' => [],
                'total_amount' => 0,
                'per_person' => 0,
                'participants_count' => 0
            ];
        }

        // Calculer le nombre de participants (organisateur + participants)
        $participants = $event->participants()->get();
        $participantCount = $participants->count() + 1; // +1 pour l'organisateur

        $expenses = [];
        $totalAmount = 0;

        DB::beginTransaction();

        try {
            foreach ($purchasedIngredients as $ingredient) {
                foreach ($ingredient->assignments as $assignment) {
                    if ($assignment->price_paid && $assignment->price_paid > 0) {
                        $shareAmount = $assignment->price_paid / $participantCount;

                        // Créer la dépense
                        $expense = new Expense();
                        $expense->event_id = $event->id;
                        $expense->ingredient_id = $ingredient->id;
                        $expense->payer_id = $assignment->user_id;
                        $expense->amount = $assignment->price_paid;
                        $expense->description = "Achat de {$ingredient->name}";
                        $expense->category = ExpenseCategory::INGREDIENT->value;
                        $expense->receipt_image = $assignment->receipt_image;
                        $expense->save();

                        // Créer la part pour l'organisateur
                        $organizerShare = new ExpenseShare();
                        $organizerShare->expense_id = $expense->id;
                        $organizerShare->user_id = $event->organizer_id;
                        $organizerShare->amount = $shareAmount;
                        $organizerShare->status = $event->organizer_id === $assignment->user_id 
                            ? ExpenseStatus::PAID->value 
                            : ExpenseStatus::PENDING->value;
                        $organizerShare->save();

                        // Créer les parts pour chaque participant
                        foreach ($participants as $participant) {
                            $participantShare = new ExpenseShare();
                            $participantShare->expense_id = $expense->id;
                            $participantShare->user_id = $participant->user_id;
                            $participantShare->amount = $shareAmount;
                            $participantShare->status = $participant->user_id === $assignment->user_id 
                                ? ExpenseStatus::PAID->value 
                                : ExpenseStatus::PENDING->value;
                            $participantShare->save();
                        }

                        $expenses[] = $this->formatExpense($expense->load(['paidBy', 'ingredient', 'shares.user']));
                        $totalAmount += $assignment->price_paid;
                    }
                }
            }

            DB::commit();

            Log::info('Dépenses calculées automatiquement', [
                'event_id' => $event->id,
                'expenses_count' => count($expenses),
                'total_amount' => $totalAmount
            ]);

            return [
                'expenses' => $expenses,
                'total_amount' => $totalAmount,
                'per_person' => $participantCount > 0 ? $totalAmount / $participantCount : 0,
                'participants_count' => $participantCount
            ];
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * {@inheritdoc}
     */
    public function getExpensesSummary(Event $event, int $userId): array
    {
        $totalExpenses = $event->expenses()->sum('amount');

        // Dépenses par utilisateur
        $expensesByUser = $event->expenses()
            ->with(['paidBy', 'ingredient', 'shares'])
            ->get()
            ->groupBy('payer_id')
            ->map(function ($expenses) {
                return [
                    'user' => $expenses->first()->paidBy,
                    'total_paid' => $expenses->sum('amount'),
                    'expenses' => $expenses->map(fn($expense) => $this->formatExpense($expense))
                ];
            });

        // Parts à payer pour l'utilisateur connecté
        $sharesToPay = ExpenseShare::whereHas('expense', function ($query) use ($event) {
                $query->where('event_id', $event->id);
            })
            ->where('status', ExpenseStatus::PENDING->value)
            ->where('user_id', $userId)
            ->with(['expense.paidBy', 'expense.ingredient'])
            ->get()
            ->map(function ($share) {
                return [
                    'id' => $share->id,
                    'amount' => $share->amount,
                    'expense' => $this->formatExpense($share->expense)
                ];
            });

        return [
            'total_expenses' => $totalExpenses,
            'expenses_by_user' => $expensesByUser,
            'shares_to_pay' => $sharesToPay,
            'user_total_to_pay' => $sharesToPay->sum('amount')
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function calculateBalances(Event $event): array
    {
        $expenses = $event->expenses()->with(['paidBy', 'shares.user'])->get();
        
        if ($expenses->isEmpty()) {
            return [
                'balances' => [],
                'reimbursements' => [],
                'total_expenses' => 0
            ];
        }

        // Calculer les soldes individuels
        $balances = [];
        $userNames = [];

        foreach ($expenses as $expense) {
            $payerId = $expense->payer_id;
            $payerName = $expense->paidBy->name;
            
            // Initialiser le solde du payeur
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

        // Filtrer les soldes significatifs (> 0.01€)
        $filteredBalances = array_filter($balances, fn($balance) => abs($balance) >= 0.01);

        // Calculer les transactions optimisées
        $transactions = $this->calculateOptimalTransactions($filteredBalances, $userNames);

        // Préparer la liste des soldes
        $balancesList = [];
        foreach ($filteredBalances as $userId => $balance) {
            $balancesList[] = [
                'user_id' => $userId,
                'user_name' => $userNames[$userId],
                'balance' => round($balance, 2)
            ];
        }

        // Trier par solde décroissant
        usort($balancesList, fn($a, $b) => $b['balance'] <=> $a['balance']);

        return [
            'balances' => $balancesList,
            'reimbursements' => $transactions,
            'total_expenses' => $expenses->sum('amount')
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function markShareAsPaid(Event $event, ExpenseShare $share, int $userId): ExpenseShare
    {
        if ($share->user_id !== $userId) {
            throw new \Exception('Vous ne pouvez marquer comme payée que vos propres parts');
        }

        if (!ExpenseStatus::fromString($share->status)->canBeMarkedAsPaid()) {
            throw new \Exception('Cette part ne peut pas être marquée comme payée');
        }

        $share->status = ExpenseStatus::PAID->value;
        $share->paid_at = now();
        $share->save();

        Log::info('Part de dépense marquée comme payée', [
            'share_id' => $share->id,
            'user_id' => $userId,
            'amount' => $share->amount
        ]);

        return $share;
    }

    /**
     * {@inheritdoc}
     */
    public function formatExpense(Expense $expense): array
    {
        return [
            'id' => $expense->id,
            'event_id' => $expense->event_id,
            'ingredient_id' => $expense->ingredient_id,
            'ingredient_name' => $expense->ingredient?->name ?? 'N/A',
            'payer_id' => $expense->payer_id,
            'payer_name' => $expense->paidBy?->name ?? 'N/A',
            'amount' => $expense->amount,
            'description' => $expense->description,
            'category' => $expense->category,
            'category_label' => $expense->category ? ExpenseCategory::fromString($expense->category)->label() : 'N/A',
            'receipt_image' => $expense->receipt_image,
            'shares' => $expense->shares?->map(function ($share) {
                return [
                    'id' => $share->id,
                    'user_id' => $share->user_id,
                    'user_name' => $share->user?->name ?? 'N/A',
                    'amount' => $share->amount,
                    'status' => $share->status,
                    'status_label' => ExpenseStatus::fromString($share->status)->label(),
                    'paid_at' => $share->paid_at
                ];
            }) ?? [],
            'created_at' => $expense->created_at,
            'updated_at' => $expense->updated_at
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function canAccessEvent(Event $event, int $userId): bool
    {
        return $event->organizer_id === $userId ||
            $event->participants()->where('user_id', $userId)->exists();
    }

    /**
     * {@inheritdoc}
     */
    public function canManageEvent(Event $event, int $userId): bool
    {
        return $event->organizer_id === $userId ||
            $event->participants()->where('user_id', $userId)->exists();
    }

    /**
     * Calcule les transactions optimales pour équilibrer les soldes
     */
    private function calculateOptimalTransactions(array $balances, array $userNames): array
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
        usort($creditors, fn($a, $b) => $b['amount'] <=> $a['amount']);
        usort($debtors, fn($a, $b) => $b['amount'] <=> $a['amount']);
        
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
