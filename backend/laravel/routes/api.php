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
    });

    // Events
    Route::apiResource('events', EventController::class);

    // Ingredients
    Route::apiResource('events.ingredients', IngredientController::class)
        ->shallow();

    // Participants
    Route::apiResource('events.participants', ParticipantController::class)
        ->shallow();
    Route::post('events/{event}/participants/invite', [ParticipantController::class, 'invite']);

    // Payments
    Route::apiResource('events.payments', PaymentController::class)
        ->shallow();
});
