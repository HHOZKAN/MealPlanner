<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\ParticipantController;
use App\Mail\TestMail;

// Route de test email (sans authentification)
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
    Route::prefix('auth')->group(function () {
        Route::get('me', [AuthController::class, 'me']);
        Route::post('logout', [AuthController::class, 'logout']);
        Route::put('profile', [AuthController::class, 'updateProfile']);
        Route::post('change-password', [AuthController::class, 'changePassword']);
    });

    // Routes des événements
    Route::prefix('events')->group(function () {
        Route::get('trashed', [EventController::class, 'trashed']);
        Route::post('{id}/restore', [EventController::class, 'restore']);
        Route::delete('{id}/force', [EventController::class, 'forceDelete']);
        Route::apiResource('/', EventController::class);
        
        // Participants
        Route::get('{event}/participants', [ParticipantController::class, 'index']);
        Route::post('{event}/participants/invite', [ParticipantController::class, 'invite']);
        Route::put('participants/{participant}', [ParticipantController::class, 'update']);
        Route::delete('participants/{participant}', [ParticipantController::class, 'destroy']);
    });

    
});