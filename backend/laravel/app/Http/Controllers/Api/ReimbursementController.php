<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Reimbursement;
use App\Models\ExpenseShare;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Traits\ApiResponse;
use Illuminate\Support\Facades\Storage;

class ReimbursementController extends Controller
{
    use ApiResponse;

    /**
     * Calculer et créer les remboursements pour un événement
     */
    public function calculateReimbursements(Event $event)
    {
        try {
            if (!$this->canAccessEvent($event)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            // Récupérer tous les participants
            $participants = $event->participants()->with('user')->get();
            
            // Calculer le bilan de chaque participant
            $balances = [];
            foreach ($participants as $participant) {
                // Montant payé
                $paid = $event->expenses()
                    ->where('paid_by', $participant->user_id)
                    ->sum('amount');
                
                // Montant dû
                $owed = ExpenseShare::whereHas('expense', function ($query) use ($event) {
                    $query->where('event_id', $event->id);
                })
                ->where('user_id', $participant->user_id)
                ->sum('amount');

                $balances[$participant->user_id] = [
                    'user' => $participant->user,
                    'balance' => $paid - $owed
                ];
            }

            // Créer les remboursements
            $reimbursements = [];
            $debtors = array_filter($balances, fn($b) => $b['balance'] < 0);
            $creditors = array_filter($balances, fn($b) => $b['balance'] > 0);

            foreach ($debtors as $debtorId => $debtor) {
                $remainingDebt = abs($debtor['balance']);
                
                foreach ($creditors as $creditorId => $creditor) {
                    if ($remainingDebt <= 0 || $creditor['balance'] <= 0) continue;

                    $amount = min($remainingDebt, $creditor['balance']);
                    
                    // Créer le remboursement
                    $reimbursement = Reimbursement::create([
                        'event_id' => $event->id,
                        'from_user_id' => $debtorId,
                        'to_user_id' => $creditorId,
                        'amount' => $amount,
                        'status' => Reimbursement::STATUS_PENDING
                    ]);

                    $reimbursements[] = $reimbursement;
                    $remainingDebt -= $amount;
                    $creditors[$creditorId]['balance'] -= $amount;
                }
            }

            return $this->successResponse([
                'reimbursements' => $reimbursements,
                'balances' => $balances
            ], 'Remboursements calculés avec succès');

        } catch (\Exception $e) {
            Log::error('Erreur lors du calcul des remboursements', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du calcul des remboursements', 500);
        }
    }

    /**
     * Marquer un remboursement comme payé
     */
    public function markAsPaid(Request $request, Event $event, Reimbursement $reimbursement)
    {
        try {
            if ($reimbursement->from_user_id !== Auth::id() && $reimbursement->to_user_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'payment_proof' => 'nullable|string', // Base64 image
                'notes' => 'nullable|string'
            ]);

            // Gérer l'upload de la preuve de paiement
            if (isset($validated['payment_proof'])) {
                $imageName = 'payment_' . time() . '.jpg';
                Storage::disk('public')->put(
                    'payments/' . $imageName,
                    base64_decode(explode(',', $validated['payment_proof'])[1])
                );
                $validated['payment_proof'] = 'payments/' . $imageName;
            }

            $reimbursement->update([
                'status' => Reimbursement::STATUS_COMPLETED,
                'payment_proof' => $validated['payment_proof'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'paid_at' => now()
            ]);

            return $this->successResponse(
                $reimbursement->load(['fromUser', 'toUser']),
                'Remboursement marqué comme payé'
            );

        } catch (\Exception $e) {
            Log::error('Erreur lors du marquage du remboursement', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du marquage du remboursement', 500);
        }
    }

    /**
     * Vérifier si l'utilisateur peut accéder à l'événement
     */
    private function canAccessEvent(Event $event)
    {
        return $event->organizer_id === Auth::id() || 
               $event->participants()->where('user_id', Auth::id())->exists();
    }
}