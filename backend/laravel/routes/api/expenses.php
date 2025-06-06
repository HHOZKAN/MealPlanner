<?php

use App\Http\Controllers\Api\Expense\ExpenseController;
use App\Http\Controllers\Api\Expense\ExpenseShareController;
use Illuminate\Support\Facades\Route;

// Routes de base des dépenses
Route::get('{event}/expenses', [ExpenseController::class, 'index']);
Route::post('{event}/expenses', [ExpenseController::class, 'store']);

// Routes de calcul et résumé (AVANT les routes avec paramètres)
Route::post('{event}/expenses/calculate', [ExpenseController::class, 'calculateExpenses']);
Route::get('{event}/expenses/summary', [ExpenseController::class, 'summary']);
Route::get('{event}/expenses/balances', [ExpenseController::class, 'balances']);

// Routes des parts de dépenses (AVANT les routes avec paramètres)
Route::get('{event}/expenses/shares/my', [ExpenseShareController::class, 'myShares']);
Route::post('{event}/expenses/shares/{share}/paid', [ExpenseShareController::class, 'markAsPaid']);
Route::post('{event}/expenses/shares/{share}/dispute', [ExpenseShareController::class, 'dispute']);
Route::post('{event}/expenses/shares/{share}/resolve', [ExpenseShareController::class, 'resolveDispute']);

// Routes avec paramètres (APRÈS les routes spécifiques)
Route::get('{event}/expenses/{expense}', [ExpenseController::class, 'show']);
Route::put('{event}/expenses/{expense}', [ExpenseController::class, 'update']);
Route::delete('{event}/expenses/{expense}', [ExpenseController::class, 'destroy']);
