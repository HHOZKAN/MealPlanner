<?php

use App\Http\Controllers\Api\Event\EventController;
use App\Http\Controllers\Api\Event\EventRestoreController;
use App\Http\Controllers\Api\ParticipantController;
use App\Http\Controllers\Api\IngredientController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\ReimbursementController;
use Illuminate\Support\Facades\Route;

Route::prefix('events')->group(function () {
    // Routes de base des événements
    Route::get('/', [EventController::class, 'index']);
    Route::post('/', [EventController::class, 'store']);
    Route::get('/{event}', [EventController::class, 'show']);
    Route::put('/{event}', [EventController::class, 'update']);
    Route::delete('/{event}', [EventController::class, 'destroy']);
    
    // Routes de restauration
    Route::get('/trashed', [EventRestoreController::class, 'trashed']);
    Route::post('/{id}/restore', [EventRestoreController::class, 'restore']);
    Route::delete('/{id}/force', [EventRestoreController::class, 'forceDelete']);

    // Participants - Inclure les routes des participants
    require __DIR__ . '/participants.php';

    // Ingrédients - Inclure les routes des ingrédients
    require __DIR__ . '/ingredients.php';

    // Dépenses - Inclure les routes des dépenses
    require __DIR__ . '/expenses.php';

    // Remboursement
    Route::post('{event}/reimbursements/calculate', [ReimbursementController::class, 'calculateReimbursements']);
    Route::post('{event}/reimbursements/paid', [ReimbursementController::class, 'markAsPaid']);
    Route::get('{event}/reimbursements/paid-history', [ReimbursementController::class, 'getPaidHistory']);
});
