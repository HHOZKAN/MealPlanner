<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Reimbursement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Traits\ApiResponse;

class ReimbursementController extends Controller
{
    use ApiResponse;

    /**
     * Marquer un remboursement comme payé
     */
    public function markAsPaid(Request $request, Event $event)
    {
        try {
            if (!$event->participants()->where('user_id', Auth::id())->exists() && $event->organizer_id !== Auth::id()) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'from_user_id' => 'required|exists:users,id',
                'to_user_id' => 'required|exists:users,id',
                'payment_proof' => 'nullable|string',
                'notes' => 'nullable|string',
            ]);

            // Créer un enregistrement du remboursement
            Reimbursement::create([
                'event_id' => $event->id,
                'from_user_id' => $validated['from_user_id'],
                'to_user_id' => $validated['to_user_id'],
                'payment_proof' => $validated['payment_proof'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'status' => 'paid',
                'paid_at' => now(),
            ]);

            // Recalculer les soldes
            $balancesController = new ExpenseController();
            $balancesResponse = $balancesController->balances($event);
            
            return $balancesResponse;

        } catch (\Exception $e) {
            Log::error('Erreur lors du marquage du remboursement comme payé', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->errorResponse('Erreur lors du marquage du remboursement: ' . $e->getMessage(), 500);
        }
    }
}
