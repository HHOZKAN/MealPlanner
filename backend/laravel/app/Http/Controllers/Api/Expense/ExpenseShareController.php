<?php

namespace App\Http\Controllers\Api\Expense;

use App\Http\Controllers\Controller;
use App\Contracts\Services\ExpenseServiceInterface;
use App\Models\Event;
use App\Models\ExpenseShare;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

/**
 * Contrôleur spécialisé pour la gestion des parts de dépenses
 * Responsabilités :
 * - Marquer les parts comme payées
 * - Gérer les statuts de paiement
 * - Historique des paiements
 */
class ExpenseShareController extends Controller
{
    use ApiResponse;

    public function __construct(
        private ExpenseServiceInterface $expenseService
    ) {}

    /**
     * Marquer une part de dépense comme payée
     * 
     * Permet à un utilisateur de marquer sa propre part comme payée.
     * Seul l'utilisateur concerné peut effectuer cette action.
     * 
     * @param Event $event
     * @param ExpenseShare $share
     * @return \Illuminate\Http\JsonResponse
     */
    public function markAsPaid(Event $event, ExpenseShare $share)
    {
        try {
            if (!$this->expenseService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            // Vérifier que la part appartient à l'événement
            if ($share->expense->event_id !== $event->id) {
                return $this->errorResponse('Part de dépense non trouvée pour cet événement', 404);
            }

            $updatedShare = $this->expenseService->markShareAsPaid($event, $share, Auth::id());

            return $this->successResponse([
                'id' => $updatedShare->id,
                'status' => $updatedShare->status,
                'paid_at' => $updatedShare->paid_at,
                'amount' => $updatedShare->amount,
                'expense' => [
                    'id' => $updatedShare->expense->id,
                    'amount' => $updatedShare->expense->amount,
                    'description' => $updatedShare->expense->description
                ]
            ], 'Part marquée comme payée avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors du marquage du paiement', [
                'error' => $e->getMessage(),
                'share_id' => $share->id,
                'user_id' => Auth::id(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du marquage du paiement: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Lister les parts de dépenses d'un utilisateur pour un événement
     * 
     * Retourne toutes les parts (payées et en attente) pour l'utilisateur connecté.
     * 
     * @param Event $event
     * @return \Illuminate\Http\JsonResponse
     */
    public function myShares(Event $event)
    {
        try {
            if (!$this->expenseService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $shares = ExpenseShare::whereHas('expense', function ($query) use ($event) {
                    $query->where('event_id', $event->id);
                })
                ->where('user_id', Auth::id())
                ->with(['expense.paidBy', 'expense.ingredient'])
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($share) {
                    return [
                        'id' => $share->id,
                        'amount' => $share->amount,
                        'status' => $share->status,
                        'status_label' => \App\ValueObjects\ExpenseStatus::fromString($share->status)->label(),
                        'paid_at' => $share->paid_at,
                        'expense' => [
                            'id' => $share->expense->id,
                            'amount' => $share->expense->amount,
                            'description' => $share->expense->description,
                            'ingredient_name' => $share->expense->ingredient?->name ?? 'N/A',
                            'payer_name' => $share->expense->paidBy?->name ?? 'N/A',
                            'created_at' => $share->expense->created_at
                        ]
                    ];
                });

            $summary = [
                'total_shares' => $shares->count(),
                'total_amount' => $shares->sum('amount'),
                'paid_amount' => $shares->where('status', 'paid')->sum('amount'),
                'pending_amount' => $shares->where('status', 'pending')->sum('amount'),
                'shares' => $shares
            ];

            return $this->successResponse($summary, 'Parts de dépenses récupérées avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des parts', [
                'error' => $e->getMessage(),
                'event_id' => $event->id,
                'user_id' => Auth::id(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la récupération des parts', 500);
        }
    }

    /**
     * Contester une part de dépense
     * 
     * Permet à un utilisateur de contester une part qui lui a été assignée.
     * 
     * @param Request $request
     * @param Event $event
     * @param ExpenseShare $share
     * @return \Illuminate\Http\JsonResponse
     */
    public function dispute(Request $request, Event $event, ExpenseShare $share)
    {
        try {
            if (!$this->expenseService->canAccessEvent($event, Auth::id())) {
                return $this->errorResponse('Non autorisé', 403);
            }

            if ($share->user_id !== Auth::id()) {
                return $this->errorResponse('Vous ne pouvez contester que vos propres parts', 403);
            }

            if ($share->expense->event_id !== $event->id) {
                return $this->errorResponse('Part de dépense non trouvée pour cet événement', 404);
            }

            $validated = $request->validate([
                'reason' => 'required|string|max:500'
            ]);

            // Vérifier que la part peut être contestée
            $status = \App\ValueObjects\ExpenseStatus::fromString($share->status);
            if (!$status->canBeDisputed()) {
                return $this->errorResponse('Cette part ne peut plus être contestée', 400);
            }

            $share->update([
                'status' => \App\ValueObjects\ExpenseStatus::DISPUTED->value,
                'dispute_reason' => $validated['reason'],
                'disputed_at' => now()
            ]);

            Log::info('Part de dépense contestée', [
                'share_id' => $share->id,
                'user_id' => Auth::id(),
                'reason' => $validated['reason']
            ]);

            return $this->successResponse([
                'id' => $share->id,
                'status' => $share->status,
                'dispute_reason' => $share->dispute_reason,
                'disputed_at' => $share->disputed_at
            ], 'Part contestée avec succès');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la contestation', [
                'error' => $e->getMessage(),
                'share_id' => $share->id,
                'user_id' => Auth::id(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la contestation: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Résoudre une contestation (organisateur seulement)
     * 
     * Permet à l'organisateur de résoudre une contestation en modifiant
     * le montant ou en annulant la part.
     * 
     * @param Request $request
     * @param Event $event
     * @param ExpenseShare $share
     * @return \Illuminate\Http\JsonResponse
     */
    public function resolveDispute(Request $request, Event $event, ExpenseShare $share)
    {
        try {
            // Seul l'organisateur peut résoudre les contestations
            if ($event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Seul l\'organisateur peut résoudre les contestations', 403);
            }

            if ($share->expense->event_id !== $event->id) {
                return $this->errorResponse('Part de dépense non trouvée pour cet événement', 404);
            }

            if ($share->status !== \App\ValueObjects\ExpenseStatus::DISPUTED->value) {
                return $this->errorResponse('Cette part n\'est pas en contestation', 400);
            }

            $validated = $request->validate([
                'action' => 'required|in:approve,modify,cancel',
                'new_amount' => 'required_if:action,modify|nullable|numeric|min:0',
                'resolution_note' => 'nullable|string|max:500'
            ]);

            switch ($validated['action']) {
                case 'approve':
                    $share->update([
                        'status' => \App\ValueObjects\ExpenseStatus::PENDING->value,
                        'resolution_note' => $validated['resolution_note'],
                        'resolved_at' => now(),
                        'resolved_by' => Auth::id()
                    ]);
                    $message = 'Contestation approuvée, part maintenue';
                    break;

                case 'modify':
                    $share->update([
                        'amount' => $validated['new_amount'],
                        'status' => \App\ValueObjects\ExpenseStatus::PENDING->value,
                        'resolution_note' => $validated['resolution_note'],
                        'resolved_at' => now(),
                        'resolved_by' => Auth::id()
                    ]);
                    $message = 'Contestation résolue, montant modifié';
                    break;

                case 'cancel':
                    $share->update([
                        'status' => \App\ValueObjects\ExpenseStatus::CANCELLED->value,
                        'resolution_note' => $validated['resolution_note'],
                        'resolved_at' => now(),
                        'resolved_by' => Auth::id()
                    ]);
                    $message = 'Contestation approuvée, part annulée';
                    break;
            }

            Log::info('Contestation résolue', [
                'share_id' => $share->id,
                'action' => $validated['action'],
                'resolved_by' => Auth::id()
            ]);

            return $this->successResponse([
                'id' => $share->id,
                'status' => $share->status,
                'amount' => $share->amount,
                'resolution_note' => $share->resolution_note,
                'resolved_at' => $share->resolved_at
            ], $message);
        } catch (\Exception $e) {
            Log::error('Erreur lors de la résolution de contestation', [
                'error' => $e->getMessage(),
                'share_id' => $share->id,
                'user_id' => Auth::id(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la résolution: ' . $e->getMessage(), 500);
        }
    }
}
