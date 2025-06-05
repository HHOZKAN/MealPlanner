<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Reimbursement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Traits\ApiResponse;
use Illuminate\Support\Facades\DB;

class ReimbursementController extends Controller
{
    use ApiResponse;

    /**
     * Marquer un remboursement comme payé
     */
    public function markAsPaid(Request $request, Event $event, ExpenseController $expenseController)
    {
        try {
            if (!$event->participants()->where('user_id', Auth::id())->exists() && $event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'from_user_id' => 'required|exists:users,id',
                'to_user_id' => 'required|exists:users,id',
                'amount' => 'required|numeric|min:0',
                'payment_proof' => 'nullable|string',
                'notes' => 'nullable|string',
            ]);

            // Vérifier que les utilisateurs sont des participants de l'événement
            if (!$event->participants()->whereIn('user_id', [$validated['from_user_id'], $validated['to_user_id']])->count() == 2) {
                return $this->errorResponse('Les utilisateurs doivent être des participants de l\'événement', 422);
            }

            // Vérifier si un remboursement similaire existe déjà
            $existingReimbursement = Reimbursement::where([
                'event_id' => $event->id,
                'from_user_id' => $validated['from_user_id'],
                'to_user_id' => $validated['to_user_id'],
                'amount' => $validated['amount'],
                'status' => 'paid',
            ])->whereDate('paid_at', now()->toDateString())->exists();

            if ($existingReimbursement) {
                return $this->errorResponse('Un remboursement similaire existe déjà pour aujourd\'hui', 422);
            }

            // Utiliser une transaction pour garantir l'intégrité des données
            return DB::transaction(function () use ($event, $validated, $expenseController) {
                // Créer un enregistrement du remboursement
                Reimbursement::create([
                    'event_id' => $event->id,
                    'from_user_id' => $validated['from_user_id'],
                    'to_user_id' => $validated['to_user_id'],
                    'amount' => $validated['amount'],
                    'payment_proof' => $validated['payment_proof'] ?? null,
                    'notes' => $validated['notes'] ?? null,
                    'status' => 'paid',
                    'paid_at' => now(),
                ]);

                // Recalculer les soldes
                $balancesResponse = $expenseController->balances($event);
                
                // Créer une réponse avec le statut et les balances
                return response()->json([
                    'status' => 'success',
                    'message' => 'Remboursement marqué comme payé',
                    'balances' => $balancesResponse->original,
                ]);
            });

        } catch (\Exception $e) {
            Log::error('Erreur lors du marquage du remboursement comme payé', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du marquage du remboursement: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Récupérer l'historique des remboursements payés
     */
    public function getPaidHistory(Event $event)
    {
        try {
            if (!$event->participants()->where('user_id', Auth::id())->exists() && $event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $paidReimbursements = Reimbursement::where('event_id', $event->id)
                ->where('status', 'paid')
                ->with(['fromUser', 'toUser'])
                ->orderBy('paid_at', 'desc')
                ->get()
                ->map(function ($reimbursement) {
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
                });

            return response()->json([
                'reimbursements' => $paidReimbursements,
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération de l\'historique des remboursements', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors de la récupération de l\'historique: ' . $e->getMessage(), 500);
        }
    }
}
