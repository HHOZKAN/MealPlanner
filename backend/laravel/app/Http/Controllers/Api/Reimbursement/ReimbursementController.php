<?php

namespace App\Http\Controllers\Api\Reimbursement;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Services\ReimbursementService;
use App\Http\Requests\MarkReimbursementAsPaidRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Traits\ApiResponse;

class ReimbursementController extends Controller
{
    use ApiResponse;

    public function __construct(
        private ReimbursementService $reimbursementService
    ) {}

    /**
     * Marquer un remboursement comme payé
     */
    public function markAsPaid(MarkReimbursementAsPaidRequest $request, Event $event)
    {
        try {
            // Vérifier l'autorisation
            if (!$event->participants()->where('user_id', Auth::id())->exists() && 
                $event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            // Vérifier que les utilisateurs sont des participants de l'événement
            if (!$event->participants()
                ->whereIn('user_id', [$request->from_user_id, $request->to_user_id])
                ->count() == 2) {
                return $this->errorResponse(
                    'Les utilisateurs doivent être des participants de l\'événement',
                    422
                );
            }

            $result = $this->reimbursementService->markAsPaid($event, $request->validated());

            return $this->successResponse([
                'message' => 'Remboursement marqué comme payé',
                'balances' => $result['balances']
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors du marquage du remboursement comme payé', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse(
                'Erreur lors du marquage du remboursement: ' . $e->getMessage(),
                500
            );
        }
    }

    /**
     * Récupérer l'historique des remboursements payés
     */
    public function getPaidHistory(Event $event)
    {
        try {
            // Vérifier l'autorisation
            if (!$event->participants()->where('user_id', Auth::id())->exists() && 
                $event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $paidReimbursements = $this->reimbursementService->getPaidHistory($event);

            return $this->successResponse([
                'reimbursements' => $paidReimbursements
            ], 'Historique des remboursements récupéré avec succès');

        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération de l\'historique des remboursements', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse(
                'Erreur lors de la récupération de l\'historique: ' . $e->getMessage(),
                500
            );
        }
    }
}
