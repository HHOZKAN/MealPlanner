<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\GroupController;
use App\Http\Controllers\Api\IngredientController;
use App\Http\Controllers\Api\ParticipantController;
use App\Http\Controllers\Api\PriceController;
use App\Http\Controllers\Api\ReimbursementController;
use App\Mail\TestMail;

// Route de test email
Route::get('/test-mail', function () {
    try {
        Mail::to('test@example.com')->send(new TestMail());
        return response()->json([
            'status' => 'success',
            'message' => 'Email envoyé avec succès'
        ]);
    } catch (\Exception $e) {
        Log::error('Erreur d\'envoi d\'email: ' . $e->getMessage());
        return response()->json([
            'status' => 'error',
            'message' => 'Erreur lors de l\'envoi de l\'email',
            'error' => $e->getMessage()
        ], 500);
    }
});

// Routes publiques
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('reset-password', [AuthController::class, 'resetPassword']);
});

// Routes protégées
Route::middleware(['auth:sanctum'])->group(function () {
    // Routes Auth
    Route::prefix('auth')->group(function () {
        Route::get('me', [AuthController::class, 'me']);
        Route::post('logout', [AuthController::class, 'logout']);
        Route::put('profile', [AuthController::class, 'updateProfile']);
        Route::post('change-password', [AuthController::class, 'changePassword']);
    });

    // Routes des événements
   Route::prefix('events')->group(function () {
        // Routes de base des événements
        Route::get('/', [EventController::class, 'index']);
        Route::post('/', [EventController::class, 'store']);
         Route::get('/{event}', [EventController::class, 'show']);
        Route::put('/{id}', [EventController::class, 'update']);
        Route::delete('/{id}', [EventController::class, 'destroy']);
        
        Route::get('/trashed', [EventController::class, 'trashed']);
        Route::post('/{id}/restore', [EventController::class, 'restore']);
        Route::delete('/{id}/force', [EventController::class, 'forceDelete']);

        // Participants
        Route::get('{event}/participants', [ParticipantController::class, 'index']);
        Route::post('{event}/participants/invite', [ParticipantController::class, 'invite']);
        Route::put('participants/{participant}', [ParticipantController::class, 'update']);
        Route::delete('participants/{participant}', [ParticipantController::class, 'destroy']);

        // Ingrédients
        Route::get('{event}/ingredients', [IngredientController::class, 'index']);
        Route::post('{event}/ingredients', [IngredientController::class, 'store']);
        Route::get('{event}/ingredients/{ingredient}', [IngredientController::class, 'show']);
        Route::put('{event}/ingredients/{ingredient}', [IngredientController::class, 'update']);
        Route::delete('{event}/ingredients/{ingredient}', [IngredientController::class, 'destroy']);
        Route::post('{event}/ingredients/{ingredient}/assign', [IngredientController::class, 'assign']);
        Route::get('{event}/ingredients/{ingredient}/assignments', [IngredientController::class, 'assignments']);
        Route::put('{event}/ingredients/{ingredient}/assignments/{assignment}', [IngredientController::class, 'updateAssignment']);

        // Dépenses
        Route::post('{event}/expenses/calculate', [ExpenseController::class, 'calculateExpenses']);
        Route::get('{event}/expenses/summary', [ExpenseController::class, 'summary']);
        Route::post('{event}/expenses/shares/{share}/paid', [ExpenseController::class, 'markAsPaid']);

        // Remboursement
        Route::post('{event}/reimbursements/calculate', [ReimbursementController::class, 'calculateReimbursements']);
        Route::post('{event}/reimbursements/{reimbursement}/paid', [ReimbursementController::class, 'markAsPaid']);
    });


    Route::prefix('prices')->group(function () {
        Route::post('/', [PriceController::class, 'store']);
        Route::get('/history', [PriceController::class, 'history']);
        Route::get('/store-stats', [PriceController::class, 'storeStats']);
    });

    Route::prefix('dashboard')->group(function () {
        Route::get('overview', [DashboardController::class, 'overview']);
        Route::get('event-history', [DashboardController::class, 'eventHistory']);
        Route::get('personal-stats', [DashboardController::class, 'personalStats']);
    });

    Route::prefix('groups')->group(function () {
        Route::get('/', [GroupController::class, 'index']);
        Route::post('/', [GroupController::class, 'store']);
        Route::get('/{group}', [GroupController::class, 'show']);
        Route::put('/{group}', [GroupController::class, 'update']);
        Route::delete('/{group}', [GroupController::class, 'destroy']);
        Route::post('/{group}/members', [GroupController::class, 'addMembers']);
        Route::delete('/{group}/members/{user}', [GroupController::class, 'removeMember']);
        Route::put('/{group}/preferences', [GroupController::class, 'updatePreferences']);
    });
});

Route::get('/test-connection', function () {
    return response()->json([
        'status' => 'success',
        'message' => 'Connexion établie avec succès',
        'timestamp' => now()->toIso8601String(),
    ]);
});
