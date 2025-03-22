<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\ParticipantController;

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