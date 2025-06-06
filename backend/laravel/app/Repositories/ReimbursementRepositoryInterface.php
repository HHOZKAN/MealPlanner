<?php

namespace App\Repositories;

use App\Models\Reimbursement;
use Illuminate\Database\Eloquent\Collection;

interface ReimbursementRepositoryInterface
{
    /**
     * Créer un nouveau remboursement
     */
    public function create(array $data): Reimbursement;

    /**
     * Vérifier si un remboursement similaire existe
     */
    public function existsSimilarReimbursement(int $eventId, array $data): bool;

    /**
     * Récupérer les remboursements payés pour un événement
     */
    public function getPaidByEvent(int $eventId): Collection;

    /**
     * Trouver un remboursement par ID
     */
    public function findById(int $id): ?Reimbursement;

    /**
     * Mettre à jour un remboursement
     */
    public function update(int $id, array $data): bool;

    /**
     * Supprimer un remboursement
     */
    public function delete(int $id): bool;
}
