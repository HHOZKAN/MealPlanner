<?php

namespace App\Services;

use App\Models\Event;
use App\Models\Reimbursement;
use App\Repositories\ReimbursementRepositoryInterface;
use App\Http\Controllers\Api\Expense\ExpenseController;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ReimbursementService
{
    public function __construct(
        private ReimbursementRepositoryInterface $reimbursementRepository,
        private ExpenseController $expenseController
    ) {}

    /**
     * Marquer un remboursement comme payé
     */
    public function markAsPaid(Event $event, array $data): array
    {
        // Vérifier si un remboursement similaire existe déjà
        if ($this->reimbursementRepository->existsSimilarReimbursement($event->id, $data)) {
            throw new \Exception('Un remboursement similaire existe déjà pour aujourd\'hui');
        }

        return DB::transaction(function () use ($event, $data) {
            // Créer un enregistrement du remboursement
            $reimbursement = $this->reimbursementRepository->create([
                'event_id' => $event->id,
                'from_user_id' => $data['from_user_id'],
                'to_user_id' => $data['to_user_id'],
                'amount' => $data['amount'],
                'payment_proof' => $data['payment_proof'] ?? null,
                'notes' => $data['notes'] ?? null,
                'status' => 'paid',
                'paid_at' => now(),
            ]);

            // Recalculer les soldes
            $balancesResponse = $this->expenseController->balances($event);
            
            return [
                'reimbursement' => $reimbursement,
                'balances' => $balancesResponse->original,
            ];
        });
    }

    /**
     * Récupérer l'historique des remboursements payés
     */
    public function getPaidHistory(Event $event): array
    {
        $paidReimbursements = $this->reimbursementRepository->getPaidByEvent($event->id);

        return $paidReimbursements->map(function ($reimbursement) {
            return [
                'id' => $reimbursement->id,
                'from_user_id' => $reimbursement->from_user_id,
                'to_user_id' => $reimbursement->to_user_id,
                'from_user_name' => $reimbursement->fromUser->name,
                'to_user_name' => $reimbursement->toUser->name,
                'amount' => $reimbursement->amount ?? 0,
                'status' => $reimbursement->status,
                'paid_at' => $reimbursement->paid_at,
                'notes' => $reimbursement->notes,
            ];
        })->toArray();
    }
}
