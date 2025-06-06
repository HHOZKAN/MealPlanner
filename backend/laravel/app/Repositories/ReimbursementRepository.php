<?php

namespace App\Repositories;

use App\Models\Reimbursement;
use Illuminate\Database\Eloquent\Collection;

class ReimbursementRepository implements ReimbursementRepositoryInterface
{
    /**
     * Créer un nouveau remboursement
     */
    public function create(array $data): Reimbursement
    {
        return Reimbursement::create($data);
    }

    /**
     * Vérifier si un remboursement similaire existe
     */
    public function existsSimilarReimbursement(int $eventId, array $data): bool
    {
        return Reimbursement::where([
            'event_id' => $eventId,
            'from_user_id' => $data['from_user_id'],
            'to_user_id' => $data['to_user_id'],
            'amount' => $data['amount'],
            'status' => 'paid',
        ])->whereDate('paid_at', now()->toDateString())->exists();
    }

    /**
     * Récupérer les remboursements payés pour un événement
     */
    public function getPaidByEvent(int $eventId): Collection
    {
        return Reimbursement::where('event_id', $eventId)
            ->where('status', 'paid')
            ->with(['fromUser', 'toUser'])
            ->orderBy('paid_at', 'desc')
            ->get();
    }

    /**
     * Trouver un remboursement par ID
     */
    public function findById(int $id): ?Reimbursement
    {
        return Reimbursement::find($id);
    }

    /**
     * Mettre à jour un remboursement
     */
    public function update(int $id, array $data): bool
    {
        return Reimbursement::where('id', $id)->update($data);
    }

    /**
     * Supprimer un remboursement
     */
    public function delete(int $id): bool
    {
        return Reimbursement::destroy($id) > 0;
    }
}
