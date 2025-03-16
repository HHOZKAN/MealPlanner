<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\IngredientController;
use App\Http\Controllers\Api\ParticipantController;
use App\Http\Controllers\Api\PaymentController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Routes publiques
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('reset-password', [AuthController::class, 'resetPassword']);

    // Routes protégées
    Route::middleware(['auth:sanctum'])->group(function () {

        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/change-password', [AuthController::class, 'changePassword']);
        
        // Route pour les événements supprimés
        Route::get('events/trashed', [EventController::class, 'trashed'])->name('events.trashed');
        Route::post('events/{id}/restore', [EventController::class, 'restore'])->name('events.restore');
        Route::delete('events/{id}/force', [EventController::class, 'forceDelete'])->name('events.force-delete');

        // Route de ressource standard
        Route::apiResource('events', EventController::class);

        // Routes pour les participants
        Route::get('events/{event}/participants', [ParticipantController::class, 'index']);
        Route::post('events/{event}/participants/invite', [ParticipantController::class, 'invite']);
        Route::put('participants/{participant}', [ParticipantController::class, 'update']);
        Route::delete('participants/{participant}', [ParticipantController::class, 'destroy']);
    });

    // Ingredients
    Route::apiResource('events.ingredients', IngredientController::class)
        ->shallow();


    // Payments
    Route::apiResource('events.payments', PaymentController::class)
        ->shallow();
});
