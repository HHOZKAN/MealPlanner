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
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Routes protégées
Route::group(['middleware' => ['auth:sanctum']], function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

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