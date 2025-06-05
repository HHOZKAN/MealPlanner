<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Expense;
use App\Models\Ingredient;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Traits\ApiResponse;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    use ApiResponse;

    /**
     * Vue d'ensemble des statistiques
     */
    public function overview()
    {
        try {
            $userId = Auth::id();

            // Statistiques générales
            $stats = [
                'events' => [
                    'total' => Event::where('organizer_id', $userId)->count(),
                    'active' => Event::where('organizer_id', $userId)
                        ->where('date', '>=', now())
                        ->count(),
                    'past' => Event::where('organizer_id', $userId)
                        ->where('date', '<', now())
                        ->count(),
                ],
                'expenses' => [
                    'total_paid' => Expense::where('payer_id', $userId)->sum('amount'),
                    'total_owed' => DB::table('expense_shares')
                        ->where('user_id', $userId)
                        ->where('status', 'pending')
                        ->sum('amount'),
                    'balance' => $this->calculateBalance($userId)
                ],
                'ingredients' => [
                    'total_assigned' => Ingredient::whereHas('assignments', function ($query) use ($userId) {
                        $query->where('user_id', $userId);
                    })->count(),
                    'purchased' => Ingredient::whereHas('assignments', function ($query) use ($userId) {
                        $query->where('user_id', $userId)
                            ->where('status', 'purchased');
                    })->count()
                ]
            ];

            return $this->successResponse($stats, 'Statistiques récupérées avec succès');
        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de la récupération des statistiques', 500);
        }
    }

    /**
     * Historique des événements
     */
    public function eventHistory(Request $request)
    {
        try {
            $events = Event::where(function ($query) {
                $query->where('organizer_id', Auth::id())
                    ->orWhereHas('participants', function ($q) {
                        $q->where('user_id', Auth::id());
                    });
            })
            ->with(['organizer', 'participants', 'expenses'])
            ->orderBy('date', 'desc')
            ->paginate(10);

            $eventStats = $events->map(function ($event) {
                return [
                    'id' => $event->id,
                    'title' => $event->title,
                    'date' => $event->date,
                    'total_expenses' => $event->expenses->sum('amount'),
                    'participant_count' => $event->participants->count() + 1, // +1 pour inclure l'organisateur
                    'your_contribution' => $this->calculateContribution($event, Auth::id()),
                    'status' => $this->getEventStatus($event)
                ];
            });

            return $this->successResponse([
                'events' => $eventStats,
                'pagination' => [
                    'total' => $events->total(),
                    'per_page' => $events->perPage(),
                    'current_page' => $events->currentPage(),
                    'last_page' => $events->lastPage()
                ]
            ], 'Historique des événements récupéré avec succès');
        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de la récupération de l\'historique', 500);
        }
    }

    /**
     * Statistiques personnelles
     */
    public function personalStats()
    {
        try {
            $userId = Auth::id();

            // Statistiques par mois
            $monthlyStats = Expense::where('paid_by', $userId)
                ->orWhereHas('shares', function ($query) use ($userId) {
                    $query->where('user_id', $userId);
                })
                ->select(
                    DB::raw('MONTH(created_at) as month'),
                    DB::raw('YEAR(created_at) as year'),
                    DB::raw('SUM(amount) as total_amount'),
                    DB::raw('COUNT(*) as transaction_count')
                )
                ->groupBy('year', 'month')
                ->orderBy('year', 'desc')
                ->orderBy('month', 'desc')
                ->get();

            // Statistiques par type d'événement
            $eventTypeStats = Event::whereHas('expenses', function ($query) use ($userId) {
                $query->where('payer_id', $userId);
            })
            ->select('type', DB::raw('COUNT(*) as count'), DB::raw('SUM(expenses.amount) as total_amount'))
            ->join('expenses', 'events.id', '=', 'expenses.event_id')
            ->groupBy('type')
            ->get();

            return $this->successResponse([
                'monthly_stats' => $monthlyStats,
                'event_type_stats' => $eventTypeStats,
                'summary' => [
                    'total_events_organized' => Event::where('organizer_id', $userId)->count(),
                    'total_events_participated' => Event::whereHas('participants', function ($query) use ($userId) {
                        $query->where('user_id', $userId);
                    })->count(),
                    'average_contribution' => $this->calculateAverageContribution($userId),
                    'most_frequent_collaborators' => $this->getMostFrequentCollaborators($userId)
                ]
            ], 'Statistiques personnelles récupérées avec succès');
        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de la récupération des statistiques personnelles', 500);
        }
    }

    private function calculateBalance($userId)
    {
        $paid = Expense::where('payer_id', $userId)->sum('amount');
        $owed = DB::table('expense_shares')
            ->where('user_id', $userId)
            ->sum('amount');
        
        return $paid - $owed;
    }

    private function calculateContribution($event, $userId)
    {
        return $event->expenses()
            ->where('payer_id', $userId)
            ->sum('amount');
    }

    private function getEventStatus($event)
    {
        if ($event->date > now()) {
            return 'upcoming';
        }
        
        $pendingExpenses = $event->expenses()
            ->whereHas('shares', function ($query) {
                $query->where('status', 'pending');
            })
            ->exists();

        return $pendingExpenses ? 'pending_payments' : 'completed';
    }

    private function calculateAverageContribution($userId)
    {
        return Expense::where('paid_by', $userId)
            ->avg('amount') ?? 0;
    }

    private function getMostFrequentCollaborators($userId)
    {
        return DB::table('participants')
            ->join('events', 'participants.event_id', '=', 'events.id')
            ->where('events.organizer_id', $userId)
            ->orWhere('participants.user_id', $userId)
            ->select('users.id', 'users.name', DB::raw('COUNT(*) as collaboration_count'))
            ->join('users', 'participants.user_id', '=', 'users.id')
            ->where('users.id', '!=', $userId)
            ->groupBy('users.id', 'users.name')
            ->orderByDesc('collaboration_count')
            ->limit(5)
            ->get();
    }
}