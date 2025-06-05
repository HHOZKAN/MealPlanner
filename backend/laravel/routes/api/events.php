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

    // Participants
    Route::get('{event}/participants', [ParticipantController::class, 'index']);
    Route::post('{event}/participants/invite', [ParticipantController::class, 'invite']);
    Route::put('participants/{participant}', [ParticipantController::class, 'update']);
    Route::delete('participants/{participant}', [ParticipantController::class, 'destroy']);
    Route::post('participants/accept-invitation', [ParticipantController::class, 'acceptInvitation']);
    Route::get('{event}/participants/share-link', [ParticipantController::class, 'generateShareableLink']);

    // Ingrédients
    Route::get('{event}/ingredients', [IngredientController::class, 'index']);
    Route::post('{event}/ingredients', [IngredientController::class, 'store']);
    Route::get('{event}/ingredients/{ingredient}', [IngredientController::class, 'show']);
    Route::put('{event}/ingredients/{ingredient}', [IngredientController::class, 'update']);
    Route::delete('{event}/ingredients/{ingredient}', [IngredientController::class, 'destroy']);
    Route::post('{event}/ingredients/{ingredient}/assign', [IngredientController::class, 'assign']);
    Route::get('{event}/ingredients/{ingredient}/assignments', [IngredientController::class, 'assignments']);
    Route::put('{event}/ingredients/{ingredient}/assignments/{assignment}', [IngredientController::class, 'updateAssignment']);
    Route::delete('{event}/ingredients/{ingredient}/assignments/{assignment}', [\App\Http\Controllers\Api\IngredientAssignmentController::class, 'destroy']);

    // Dépenses
    Route::get('{event}/expenses', [ExpenseController::class, 'index']);
    Route::post('{event}/expenses', [ExpenseController::class, 'store']);
    Route::put('{event}/expenses/{expense}', [ExpenseController::class, 'update']);
    Route::post('{event}/expenses/calculate', [ExpenseController::class, 'calculateExpenses']);
    Route::get('{event}/expenses/summary', [ExpenseController::class, 'summary']);
    Route::get('{event}/expenses/balances', [ExpenseController::class, 'balances']);
    Route::post('{event}/expenses/shares/{share}/paid', [ExpenseController::class, 'markAsPaid']);

    // Remboursement
    Route::post('{event}/reimbursements/calculate', [ReimbursementController::class, 'calculateReimbursements']);
    Route::post('{event}/reimbursements/paid', [ReimbursementController::class, 'markAsPaid']);
    Route::get('{event}/reimbursements/paid-history', [ReimbursementController::class, 'getPaidHistory']);
});
