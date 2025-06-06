<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\IngredientController;
use App\Http\Controllers\Api\ParticipantController;
use App\Http\Controllers\Api\PriceController;
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
    require __DIR__ . '/api/events.php';
    
    // Routes des remboursements
    require __DIR__ . '/api/reimbursements.php';

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
});

Route::get('/test-connection', function () {
    return response()->json([
        'status' => 'success',
        'message' => 'Connexion établie avec succès',
        'timestamp' => now()->toIso8601String(),
    ]);
});
